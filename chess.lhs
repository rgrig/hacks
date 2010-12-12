\documentclass{article}
%include polycode.fmt

\begin{document}

> import Array
> import Data.Bits
> import Data.Char
> import Data.Function
> import qualified Data.IntSet as IS
> import Data.List


We are given an $m \times n$ board whose squares are either black or white.  We
should cut out chessboards out of it in a particular order: First prefer big
boards, then those close to the top, and then those to the left. Each choice is
made locally. We only need to report, for each size, how many chessboards of
that size we end up cutting.

> type Matrix a = Array (Int, Int) a
> solve :: Matrix Bool -> [(Int, Int)]

Given a board coloring and a set with what was cut out we can
easily compute the biggest chess board that can be cut and has the top-left
corner at~$(i,j)$, for all~$(i,j)$, using dynamic programming.

> largestSizes :: Matrix Bool -> IISet -> Matrix Int

The basic strategy will be as follows. First we find the largest size. Then
we scan the board and whenever we see the largest size we check whether it
can be cut. (It may be that one board we cut earlier in \textit{this} scan
makes it impossible to cut the board we look at now.) For each board we
can decide in constant time whether it can be cut, by checking if its two
top corners are still uncut. This ignores the time needed to mark squares
as cut. But that time is clearly~$\Theta(n^2)$ in total. (Well, at least
assuming that insertion in the set of `cuts' and memebrship testing take
constant time, which won't be the case in this implementation.)
So, one scan 
takes $\Theta(n^2)$~time. How many scans are possible? We have many scans when
we cut a little, so in the worst case we have $\alpha$ scans with
\[ 1^2 + 2^2 + 3^2 + \cdots + \alpha^2 \sim \alpha^3 \preceq n^2 \]
That is, the total running time is $O(n^{2+2/3})$. When $n\sim 2^9$,
the running time is $\sim 2^{24}$, which seems fast enough.

Let's begin by implementing |largestBoards|.

> largestSizes colors cuts = sizes 
>   where
>     sizes = array (bounds colors) [(i, sz i) | i <- indices colors]
>     sz (i, j) 
>       | mem (i, j) cuts = 0
>       | i == m || j == n || h == r || h == d || h /= dr = 1
>       | otherwise = 1 + (minimum $ map (sizes!) [(i+1, j), (i, j+1), (i+1,j+1)])
>       where
>         [h, d, r, dr] = map (colors!) [(i,j), (i+1,j), (i,j+1), (i+1,j+1)]
>         (m, n) = snd (bounds colors)

The |largestSizes| are computed once for each size |k| that appears |count>0|
times in the output. Each |sizes| matrix is folded over while accumulating
|cuts| and |count|ing cut boards.

> solve colors = unfoldr step IS.empty
>   where
>     step cuts
>       | IS.size cuts == m * n = Nothing
>       | otherwise = Just ((k, count), newCuts)
>       where
>         sizes = largestSizes colors cuts
>         k = maximum (elems sizes)
>         (newCuts, count) = foldl (cutSize n k) (cuts, 0) (assocs sizes)
>         (m, n) = snd (bounds colors)

Finally, we need to cut individual boards, if possible.

> cutSize :: Int -> Int -> (IISet, Int) -> ((Int, Int), Int) -> (IISet, Int)
> cutSize n k (cuts, count) ((i, j), k')
>   | k /= k' || (i, j) `mem` cuts || j+k-1 > n || (i, j+k-1) `mem` cuts = 
>       (cuts, count)
>   | otherwise = (foldl add cuts $ range ((i,j),(i+k-1,j+k-1)), succ count)

Now boring IO.

> parse (x:xs) = (mkMatrix (m, n) (map (concatMap bitsOfHex) ls), rs)
>   where 
>     (ls, rs) = splitAt m xs
>     [m, n] = map read (words x)
> bitsOfHex d = [testBit x i | i <- [3,2,1,0]] where x = digitToInt d

I'm not sure if something more horrible than |mkMatrix| is possible.

> mkMatrix (m, n) xs = array ((1,1),(m,n)) (zipWith (,) [1..] xs >>= f)
>   where  f (i, xxs) = zipWith (\ j x -> ((i,j), x)) [1..] xxs
>
> chop :: ([a] -> (b, [a])) -> [a] -> [b]
> chop _ [] = []
> chop f xs = y : chop f xs' where (y, xs') = f xs

The main loop.

> fmt a = map concat $ chunk n $ map show $ elems a
>     where 
>       n = snd $ snd $ bounds a
>       chunk n [] = [[]]
>       chunk n xs = ls : chunk n rs
>         where (ls, rs) = splitAt n xs

> main = interact (unlines . report . map solve . chop parse . tail . lines)

And the printing.

> report xs = (zip [1..] xs) >>= f
>   where
>     f (t, rs) = ("Case #" ++ show t ++ ": " ++ show (length rs)) : map g rs
>     g (a, b) = show a ++ " " ++ show b

The set operations:

> type IISet = IS.IntSet
> iisHash (a, b) = a + 1000 * b
> add :: IISet -> (Int, Int) -> IISet
> add s x = IS.insert (iisHash x) s
> mem :: (Int, Int) -> IISet -> Bool
> mem x s = IS.member (iisHash x) s

\end{document}
