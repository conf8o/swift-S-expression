(require '[clojure.string :as string]
         '[clojure.java.io :as io])

(defn remove-public [s]
  (string/replace s #"public " ""))

(def base (io/file "../Sources/swift-S-expression"))

(def source-priority
  {"Obj.swift" "0"
   "Env.swift" "1"})

(defn source-sort-key [f]
  (let [f-name (.getName f)]
    (if-let [k (source-priority f-name)]
      k
      f-name)))

(defn sources [folder]
  (for [f (sort-by source-sort-key (file-seq folder))
        :let [f-name (.getName f)]
        :when (and (re-find #".swift$" f-name)
                   (not (re-find #"main.swift$" f-name)))]
    (str "//===--- " f-name " ---===//\n\n"
         (slurp f))))


(->> base
     sources
     (map remove-public)
     (string/join "\n\n")
     (spit "gathered.swift"))
