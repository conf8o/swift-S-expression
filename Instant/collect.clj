(require '[clojure.string :as string]
         '[clojure.java.io :as io])

(defn remove-public [s]
  (string/replace s #"public " ""))

(def base (io/file "../Sources/swift-S-expression"))

(defn sources [folder]
  (for [f (file-seq folder)]
    (slurp f)))

(->> base
     sources
     (map remove-public)
     (string/join "\n\n")
     (spit "output.swift"))
