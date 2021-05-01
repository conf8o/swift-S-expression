/// 組み込み環境
public let BUILTIN_ENV = BUILTIN_FUNCTION
    .merging(BUILTIN_CLOSED_OPERATOR, uniquingKeysWith: { (_, new) in  new })
    .merging(BUILTIN_COMPARISON_OPERATOR, uniquingKeysWith: { (_, new) in new })
    .merging(BUILTIN_SPECIAL_FORM, uniquingKeysWith: { (_, new) in new })
