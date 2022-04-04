module Library (
    Point,
    Link,
    splitPoints,
    createPoints,
    distEucl,
    groupLinks,
    posLink,
    biggerLinks,
    orgLinks,
    verifCut,
    createGroups,
    orgGroups,
    toString
) where

import Data.List

-- Define o tipo Point que contem um int para identificar o numero do
-- ponto e um array de Double para ter as coordenadas
type Point = (Int, [Double])

-- Define o tipo Link que contem uma list de pontos e um Double com
-- a distancia entre eles
type Link = ([Point], Double)


-- Separa a string que foi lida por virgula
-- Exemplo: "1.1,2.2,3.3" se torna ["1.1", "2.2", "3.3"]
wordsWhen     :: (Char -> Bool) -> String -> [String]
wordsWhen p s =  case dropWhile p s of
                      "" -> []
                      s' -> w : wordsWhen p s''
                            where (w, s'') = break p s'

-- Retira as dimensoes de um ponto usando a funcao wordsWhen que faz a separacao
-- por virgulas e depois converte os valores de dimensao para Double
splitPoints :: String -> [Double]
splitPoints file = do
    let points = filter (/="") $ wordsWhen (==',') file
    map read points :: [Double]

-- Usa a list com as informações lidas para criar uma list de pontos
createPoints :: [[Double]] -> [Point]
createPoints dataset = list
  where
    list = zip [1..] dataset

-- Calcula a distancia euclidiana entre dois pontos
distEucl :: Point -> Point -> Double
distEucl p1 p2 = summation ** (1.0/2)
 where
     x = snd p1
     y = snd p2
     summation = sum $ zipWith pointwiseDist x y
     pointwiseDist xi yi = abs (xi - yi) ** 2

-- Cria um link entre dois pontos
criaLink :: Point -> Point -> Double -> Link
criaLink p1 p2 d = ([p1,p2], d)

-- Cria uma list de links, através do caminho, verificando quais sao os pontos mais próximos
groupLinks :: [Point] -> Point -> [Link]
groupLinks lp p
    | null lp || length lp == 1  = [] --Verifica se os pontos acabaram ou se tem apenas o ultimo ponto corrente
    | otherwise = links
    where
        newlist = delete p lp -- Apaga o ponto corrente da list
        dists = map (distEucl p) newlist -- Cria uma list com as distâncias do ponto corrente com todos os outros
        points = zip newlist dists -- Junta as distâncias dos pontos e o ponto corrente aos pontos em si
        orgList = sortBy (\(_,a) (_,b) -> compare a b) points -- Organiza a list por distância
        smallDist = snd $ head orgList -- Pega a menor distância
        smallPoint = fst $ head [x | x <- orgList, snd x == smallDist] -- Retira o ponto com a menor distância
        link = criaLink p smallPoint smallDist -- Cria link entre os dois pontos
        links = link:groupLinks newlist smallPoint

-- Retorna um inteiro com a posição que determinado link está na list
posLink::[Link]->Link->Int
posLink [] x = 0
posLink (a:t) x | x == a = 1
 | otherwise = 1 + posLink t x

-- Retorna uma list com os maiores links de acordo com k. K grupos = K-1 links
biggerLinks :: [Link] -> Int -> [Link]
biggerLinks links k
    | k == 0|| k == 1 = []
    | otherwise = maiores
    where
        orgList = sortBy (\(_,a) (_,b) -> compare a b) links -- Organiza a list por distância
        maxDist = snd $ last orgList -- Pega a maior distancia
        bigLink = head [x | x <- orgList, snd x == maxDist] -- Pega o ultimo elemento, que possui a maior distancia
        newlist = delete bigLink links -- Deleta o link da list
        maiores = bigLink:biggerLinks newlist (k-1)

-- Faz a transformacao de um Link no formato ([Point, Point], Double) para (Int,Int) para melhor
-- visualização e manipulação
orgLinks :: Link -> (Int,Int)
orgLinks link = points
    where
        p1 = fst $ head $ fst link 
        p2 = fst $ last $ fst link
        points = (p1,p2)


-- Cria os grupos de acordo com a list dos maiores links que devem ser apagados
createGroups :: [(Int,Int)] -> [Int] -> [[(Int,Int)]]
createGroups list biglinks
    | null biglinks = [list]
    | otherwise = filter (not.null) finallist -- Filtro: retira as listas vazias
    where
        cut = head biglinks -- Pega a primeira posição onde haverá o corte da lista na maior aresta
        head1 = take (cut-1) list -- Retira o começo da lista até antes do corte 
        head2 = drop cut list -- Retira o que sobrou da lista depois do corte
        extra = verifCut cut list -- Verifica se a aresta cortada é a ultima ou a primeira da lista
        added = head2 : extra -- Adiciona o resto da lista inicial e o que a verifCut retornou
        newblinks = delete (head biglinks) biglinks -- Remove o link usado da lista inicial
        finallist = added ++ createGroups head1 newblinks 

-- Verifica se a aresta cortada é a ultima ou a primeira da lista
-- Sendo a primeira OU a ultima, retorna o primeiro ou o ultimo ponto com 0 numa tupla -> [[(P1, 0)]] OU [[(P2, 0)]]
-- Nos casos onde a aresta que vai ser excluida é a unica, ele tem que retornar os dois pontos
-- então ele retorna [[(P1, 0)], [(P2, 0)]]
verifCut :: Int -> [(Int, Int)] -> [[(Int, Int)]]
verifCut cut list
  | length list == 1 && cut == 1 = [[(fst(head list), 0)],[(snd(head list), 0)]]
  | cut == 1 = [[(fst(head list), 0)]]
  | cut == length list = [[(snd(last list), 0)]]
  | otherwise = []

-- Organiza os grupos retirando os pontos das tuplas e removendo os pontos duplicados
-- ex.: [(1,2)(2,3)(3,4)] -> [1,2,3,4]
orgGroups :: [(Int,Int)] -> [Int]
orgGroups list
 | null list = []
 | otherwise = nub organized
 where
     ponto = head list
     newlist = delete ponto list
     organized = [fst ponto]++[snd ponto]++orgGroups newlist

-- Transforma um grupo de ints em uma string
-- ex.: [1,2,3,4] -> "1,2,3,4"
toString :: [Int] -> String
toString list
    | null list = []
    | otherwise = groupFormatted
        where
            groupStr = map show list
            groupFormatted = intercalate ", " groupStr
