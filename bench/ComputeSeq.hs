{-# LANGUAGE BangPatterns     #-}
{-# LANGUAGE FlexibleContexts #-}
module Main where

import           Compute
import           Criterion.Main
import           Data.Array.Massiv                  as M
import           Data.Array.Repa                    as R
import           Data.Foldable
import qualified Data.Vector.Unboxed                as VU
import           Prelude                            as P

main :: IO ()
main = do
  let !sz = (1600, 1200) :: M.DIM2
  let !ixM = (1000, 999)
      !ixR = (Z :. 1000 :. 999)
      !ix1D = toLinearIndex sz ixM
  let !arrCM = M.computeUnboxedS $ arrM sz
      !arrCMM = toManifest arrCM
      !arrCR = R.computeUnboxedS $ arrR sz
      !vecCU = vecU sz
  defaultMain
    [ bgroup
        "Indexing"
        [ bgroup
            "Unsafe"
            [ bench "Massiv 2D" $ whnf (M.unsafeIndex arrCM) ixM
            , bench "Vector 1D" $ whnf (VU.unsafeIndex vecCU) ix1D
            , bench "Repa 2D" $ whnf (R.unsafeIndex arrCR) ixR
            ]
        , bgroup
            "Safe"
            [ bench "Massiv 2D: maybeIndex" $
              whnf (maybe (error "impossible") id . M.maybeIndex arrCM) ixM
            , bench "Massiv 2D: index" $ whnf (M.index arrCM) ixM
            , bench "Massiv 2D: (!) . (<!)" $
              whnf (\ (i, j) -> (toManifest arrCM) <! j M.! i) ixM
            , bench "Massiv 2D: (!) . (!>)" $
              whnf (\ (i, j) -> (toManifest arrCM) !> i M.! j) ixM
            , bench "Massiv 2D: (!) . (<!>)" $
              whnf (\ (i, j) -> (toManifest arrCM) <!> (1, i) M.! j) ixM
            , bench "Massiv 2D: (!) . (<!>)" $
              whnf (\ (i, j) -> (toManifest arrCM) <!> (2, j) M.! i) ixM
            , bench "Vector 1D" $ whnf (vecCU VU.!) ix1D
            , bench "Repa 2D" $ whnf (R.index arrCR) ixR
            ]
        , bgroup
            "Linear Unsafe"
            [ bench "Massiv 2D" $ whnf (M.unsafeLinearIndex arrCM) ix1D
            , bench "Vector 1D" $ whnf (VU.unsafeIndex vecCU) ix1D
            , bench "Repa 2D" $ whnf (R.unsafeLinearIndex arrCR) ix1D
            ]
        ]
    , bgroup
        "Load"
        [ bgroup
            "Light"
            [ bench "Array Massiv" $ whnf (M.computeUnboxedS . arrM) sz
            , bench "Vector Unboxed" $ whnf vecU sz
            , bench "Array Repa" $ whnf (R.computeUnboxedS . arrR) sz
            ]
        , bgroup
            "Heavy"
            [ bench "Array Massiv" $ whnf (M.computeUnboxedS . arrM') sz
            , bench "Vector Unboxed" $ whnf vecU' sz
            , bench "Array Repa" $ whnf (R.computeUnboxedS . arrR') sz
            ]
        , bgroup
            "Windowed"
            [ bench "Array Massiv" $ whnf (M.computeUnboxedS . arrWindowedM) sz
            , bench "Array Repa" $ whnf (R.computeUnboxedS . arrWindowedR) sz
            ]
        ]
    , bgroup
        "Fold"
        [ bgroup
            "Left"
            [ bench "Array Massiv Delayed" $ whnf (foldl' (+) 0 . arrM) sz
            , bench "Vector Unboxed" $ whnf (VU.foldl' (+) 0 . vecU) sz
            , bench "Array Repa" $ whnf (R.foldAllS (+) 0 . arrR) sz
            ]
        , bgroup
            "Right"
            [ bench "Array Massiv Delayed" $ whnf (foldrS (+) 0 . arrM) sz
            , bench "Array Massiv Delayed foldr" $ whnf (foldr (+) 0 . arrM) sz
            , bench "Array Massiv Delayed foldr'" $ whnf (foldr' (+) 0 . arrM) sz
            , bench "Vector Unboxed" $ whnf (VU.foldr' (+) 0 . vecU) sz
            , bench "Array Repa" $ whnf (R.foldAllS (+) 0 . arrR) sz
            ]
        , bgroup
            "Computed"
            [ bench "Array Massiv Unboxed Left Fold" $ whnf (foldlS (+) 0) arrCM
            --, bench "Array Massiv Unboxed Left Fold'" $ whnf (foldlS' (+) 0) arrCM
            , bench "Array Massiv Unboxed Right Fold" $ whnf (foldrS (+) 0) arrCM
            --, bench "Array Massiv Unboxed Right Fold'" $ whnf (foldrS' (+) 0) arrCM
            , bench "Array Massiv Manifest Left Fold" $ whnf (foldlS (+) 0) arrCMM
            --, bench "Array Massiv Manifest Left Fold'" $ whnf (foldlS' (+) 0) arrCMM
            , bench "Array Massiv Manifest Right Fold" $ whnf (foldrS (+) 0) arrCMM
            --, bench "Array Massiv Manifest Right Fold'" $ whnf (foldrS' (+) 0) arrCMM
            , bench "Vector Unboxed Left Strict" $ whnf (VU.foldl' (+) 0) vecCU
            , bench "Vector Unboxed Right Strict" $ whnf (VU.foldr' (+) 0) vecCU
            , bench "Array Repa FoldAll" $ whnf (R.foldAllS (+) 0) arrCR
            ]
        ]
    , bgroup
        "toList"
        [ bench "Array Massiv" $ nf (M.toListS1D . arrM) sz
        , bench "Array Massiv 2D" $ nf (M.toListS2D . arrM) sz
        , bench "Array vector" $ whnf (VU.toList . vecU) sz
        , bench "Array Repa" $ nf (R.toList . arrR) sz
        ]
    , bgroup
        "Fuse"
        [ bgroup
            "map"
            [ bench "Array Massiv" $
              whnf (M.computeUnboxedS . M.map (+ 25) . arrM) sz
            , bench "Vector Unboxed" $ whnf (VU.map (+ 25) . vecU) sz
            , bench "Array Repa" $
              whnf (R.computeUnboxedS . R.map (+ 25) . arrR) sz
            ]
        ]
    , bgroup
        "Append"
        [ bgroup
            "append"
            [ bench "Array Massiv" $
              whnf
                (\sz' -> M.computeUnboxedS $ M.append' 1 (arrM sz') (arrM sz'))
                sz
            , bench "Vector Unboxed" $
              whnf (\sz' -> (vecU sz') VU.++ (vecU sz')) sz
            , bench "Array Repa" $
              whnf
                (\sz' -> R.computeUnboxedS $ R.append (arrR sz') (arrR sz'))
                sz
            ]
        ]
    ]
