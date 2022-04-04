-- Trabalho 1 - Programação I - 2021/2
-- Aluna: Lohayne Malavasi Camillo
-- Matrícula: 2019202164

import Data.Char
import Data.List
import System.IO
import Library

main :: IO ()
main = do
    putStrLn "Digite o nome do arquivo de entrada:"
    input <- getLine
    putStrLn "Digite o nome do arquivo de saida"
    output <- getLine
    putStrLn "Digite o número de grupos (K):"
    groups <- getLine
    let k = read groups :: Int
    c <- readFile input
    let dataset = map splitPoints (lines c) -- Separa os pontos a partir do que foi lido e cria uma lista com as coordenadas
    let listpoints = createPoints dataset -- Lista dos pontos lidos
    let listlinks = groupLinks listpoints (head listpoints) -- Lista das conexões criadas
    let listbigger = biggerLinks listlinks k -- Lista das maiores conexões com length == k
    let biggerk = reverse (sort (map (posLink listlinks) listbigger)) -- Lista com as posições das maiores conexões - 2,4,6 -> 6,4,2
    let linksorganized = map orgLinks listlinks -- Lista com as arestas transformadas. Passa de ([Id, Id], distancia) para (Id, Id)
    let listgroups = createGroups linksorganized biggerk -- Cria uma lista com as listas dos grupos
    let listGOrg = map orgGroups listgroups -- Organiza os grupos tirando-os das tuplas
    let listGFinal = map (delete 0) listGOrg -- Deleta os 0 provenientes da função verifCut
    let groupStr = unlines(map toString listGFinal) -- Cria uma string com tudo a ser impresso
    writeFile output groupStr -- Imprime no arquivo
    putStrLn "Agrupamentos:"
    putStrLn groupStr --Imprime no terminal
    return()