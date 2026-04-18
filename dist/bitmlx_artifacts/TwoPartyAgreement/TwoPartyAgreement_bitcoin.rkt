#lang bitml

(debug-mode)

(participant "A" "pkA")
(participant "B" "pkB")

(contract
 (pre
  (deposit "A" 1 "A_deposit_Bitcoin")
  (deposit "B" 0 "B_deposit_Bitcoin")
  (secret "A" a "0e0ea2826e92e3281dd19f15b1655fed95be41538f13f4e6b38dc58477675236")
  (secret "B" b "b980772f00958e58d8cd997f44cbfbfdf08dde860e0cb68c92ad37db7fd28d99")
  (secret "A" StepSecret_A__L_ "bf5b983e7b715c34230ffb9ccd4861a3eb5e7c3d07898af91fce3409d769ab48")
  (secret "B" StepSecret_B__L_ "3be39541077d766682abeffc14e411ce67a0929861c86eea3f3a9e3d732a7a32")
  (secret "A" StepSecret_A__LL_ "9f579268bd536d7e451fc01efb09c17d0aac34b6b443374faa208e3035194afb")
  (secret "B" StepSecret_B__LL_ "efeb7add1c00eb9e502463c749cd12157d6256e5d270cfbe7331a6ba596f9042")
  (secret "A" StepSecret_A__LRL_ "62bfb3a8b766213f27a13a38e83e3f0817aed0689dd525365318d312420d1279")
  (secret "B" StepSecret_B__LRL_ "3a9028f68afac12660dea4178a5b678aa1bae66e0715a0eace82596daeac87a5")
  (secret "A" StartSecret_A "1b36752da6e88fa13d56ce722c5eb6e38c72086933ff0d7e9faafbe963bb9287")
  (secret "B" StartSecret_B "76336ff13edf823720da85e9e82da9d2b3f38da9d6883501f083e2b5c863881e")
  )

 (choice
  (reveal (StepSecret_A__L_ StartSecret_A StartSecret_B) (choice
                                                          (revealif (StepSecret_A__LL_ a b) (pred (and (between b 0 1) (= a b))) (withdraw "B"))
                                                          (revealif (StepSecret_B__LL_ a b) (pred (and (between b 0 1) (= a b))) (withdraw "B"))
                                                          (after 21 (reveal () (choice
                                                                                (reveal (StepSecret_A__LL_) (withdraw "B"))
                                                                                (reveal (StepSecret_B__LL_) (withdraw "A"))
                                                                                (after 31 (reveal () (choice
                                                                                                      (revealif (StepSecret_A__LRL_ a b) (pred (and (between b 0 1) (!= a b))) (withdraw "A"))
                                                                                                      (revealif (StepSecret_B__LRL_ a b) (pred (and (between b 0 1) (!= a b))) (withdraw "A"))
                                                                                                      (after 41 (reveal () (choice
                                                                                                                            (reveal (StepSecret_A__LRL_) (withdraw "B"))
                                                                                                                            (reveal (StepSecret_B__LRL_) (withdraw "A"))
                                                                                                                            (after 51 (reveal () (withdraw "A"))
                                                                                                                             )
                                                                                                                            ))
                                                                                                       )
                                                                                                      ))
                                                                                 )
                                                                                ))
                                                           )
                                                          ))
  (reveal (StepSecret_B__L_ StartSecret_A StartSecret_B) (choice
                                                          (revealif (StepSecret_A__LL_ a b) (pred (and (between b 0 1) (= a b))) (withdraw "B"))
                                                          (revealif (StepSecret_B__LL_ a b) (pred (and (between b 0 1) (= a b))) (withdraw "B"))
                                                          (after 21 (reveal () (choice
                                                                                (reveal (StepSecret_A__LL_) (withdraw "B"))
                                                                                (reveal (StepSecret_B__LL_) (withdraw "A"))
                                                                                (after 31 (reveal () (choice
                                                                                                      (revealif (StepSecret_A__LRL_ a b) (pred (and (between b 0 1) (!= a b))) (withdraw "A"))
                                                                                                      (revealif (StepSecret_B__LRL_ a b) (pred (and (between b 0 1) (!= a b))) (withdraw "A"))
                                                                                                      (after 41 (reveal () (choice
                                                                                                                            (reveal (StepSecret_A__LRL_) (withdraw "B"))
                                                                                                                            (reveal (StepSecret_B__LRL_) (withdraw "A"))
                                                                                                                            (after 51 (reveal () (withdraw "A"))
                                                                                                                             )
                                                                                                                            ))
                                                                                                       )
                                                                                                      ))
                                                                                 )
                                                                                ))
                                                           )
                                                          ))
  (after 11 (reveal () (choice
                        (reveal (StepSecret_A__L_) (withdraw "B"))
                        (reveal (StepSecret_B__L_) (withdraw "A"))
                        (after 21 (reveal () (withdraw "A"))
                         )
                        ))
   )
  ))
