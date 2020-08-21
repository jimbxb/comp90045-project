module PrettyRoo (pprint) where

import RooAST

import Data.L (intercalate)

pprint :: Program -> String
pprint (Program r a p) 
  = intercalate "\n" [ decs pRecord r
                     , decs pArray a
                     , (if null r && null a then "" else "\n")
                       ++ intercalate "\n" (map pProcedure p)
                     ]
  where
    decs _ [] = ""
    decs p ds = intercalate "\n" (map p ds)

pDecl :: Decl -> String
pDecl (Decl t i) = pTypeName t ++ " " ++ i

pStmt :: [Stmt] -> String
pStmt ss = intercalate "\n" (pStmtL ss)

pStmtL :: [Stmt] -> [String]
pStmtL ss = concatMap (map indent . pStmt') ss
  where
    pStmt' :: Stmt -> [String]
    pStmt' (Assign l e)     = [ pLValue l ++ " <- " ++ pExpr e ++ ";" ]
    pStmt' (Read l)         = [ "read " ++ pLValue l ++ ";" ]
    pStmt' (Write e)        = [ "write " ++ pExpr e ++ ";" ]
    pStmt' (Writeln e)      = [ "writeln " ++ pExpr e ++ ";" ]
    pStmt' (If e ss)        = [ "if " ++ pExpr e ++ " then" ]
                              ++ pStmtL ss
                              ++ [ "fi" ]
    pStmt' (IfElse e ts fs) = [ "if " ++ pExpr e ++ " then" ]
                              ++ pStmtL ts 
                              ++ [ "else" ]
                              ++ pStmtL fs
                              ++ [ "fi" ]
    pStmt' (While e ss)     = [ "while " ++ pExpr e ++ " do" ]
                              ++ pStmtL ss
                              ++ [ "od" ]
    pStmt' (Call f es)      = [ "call " ++ f ++ "(" ++ pExprL es ++ ");" ]

pExpr :: Expr -> String
pExpr (Lval l)          = pLValue l
pExpr (BoolConst b)     = if b then "true" else "false"
pExpr (IntConst i)      = show i
pExpr (StrConst s)      = show s
pExpr (UnOpExpr o e)    = pUnOp o ++ (if isOp e
                                      then paren (pExpr e)
                                      else (pExpr e))
pExpr (BinOpExpr o l r) = binParen isRAssoc o l
                          ++ pBinOp o
                          ++ binParen isLAssoc o r
  where 
    binParen r o e = if opPrec o < prec e || (opPrec o == prec e && r o)
                     then paren (pExpr e) 
                     else pExpr e
    prec (BinOpExpr o _ _) = opPrec o 
    prec _                 = -1 

pExprL :: [Expr] -> String
pExprL es = intercalate ", " (map pExpr es)

pUnOp :: UnOp -> String
pUnOp Op_not = "not "
pUnOp Op_neg = "-"

pBinOp :: BinOp -> String
pBinOp Op_or  = " or "
pBinOp Op_and = " and "
pBinOp Op_eq  = " = "
pBinOp Op_neq = " != "
pBinOp Op_ls  = " < "
pBinOp Op_leq = " <= "
pBinOp Op_gt  = " > "
pBinOp Op_geq = " >= "
pBinOp Op_add = " + "
pBinOp Op_sub = " - "
pBinOp Op_mul = " * "
pBinOp Op_div = " / "

pLValue :: LValue -> String
pLValue (LId i)           = i
pLValue (LField i f)      = i ++ "." ++ f
pLValue (LInd i e)        = i ++ "[" ++ pExpr e ++ "]"
pLValue (LIndField i e f) = i ++ "[" ++ pExpr e ++ "]." ++ f

pProcedure :: Procedure -> String
pProcedure (Procedure ps ds ss i ) = "procedure " ++ i 
                                       ++ " (" ++ pParamL  ps ++")\n" 
                                     ++ decls ds ++ "{\n" ++ pStmt ss 
                                     ++ if null ss then "}\n" else "\n}\n"
  where 
    decls [] = []
    decls ds = intercalate ";\n" (map (indent . pDecl) ds) ++ ";\n"

pParam :: Parameter -> String
pParam (ParamVal (Decl t i)) = pTypeName t ++ " val " ++ i
pParam (ParamRef (Decl t i)) = pTypeName t ++ " " ++ i 

pParamL  :: [Parameter] -> String
pParamL  ds = intercalate ", " (map pParam ds)

pArray :: ArrayDef -> String
pArray (Array s t i) = "array [" ++ show s ++ "] " 
                       ++ pTypeName t ++ " " ++ i ++ ";"

pRecord :: RecordDef -> String
pRecord (Record d i) = "record \n" ++ indent "{ " ++ fields ++ "\n"
                                   ++ indent "} " ++ i ++ ";"
  where fields = intercalate ("\n" ++ indent "; ") (map pDecl d) 

pTypeName :: TypeName -> String
pTypeName BoolType      = "boolean"
pTypeName IntType       = "integer"
pTypeName (TypeAlias i) = i

indent :: String -> String
indent s = replicate 4 ' ' ++ s

paren :: String -> String
paren s = "(" ++ s ++ ")"

isLAssoc :: BinOp -> Bool
isLAssoc _ = True

isRAssoc :: BinOp -> Bool
isRAssoc = not . isLAssoc

opPrec :: BinOp -> Int
opPrec Op_mul = 1
opPrec Op_div = 1
opPrec Op_add = 2
opPrec Op_sub = 2
opPrec Op_and = 4
opPrec Op_or  = 5
opPrec _      = 3

isOp :: Expr -> Bool
isOp (BinOpExpr _ _ _) = True
isOp (UnOpExpr _ _)    = True
isOp _                 = False
