# Blockchain project (BitMLx + BitML toolchain)

1. Biên dịch BitMLx (Haskell) ra BitML (Racket, `#lang bitml`) cho Bitcoin/Dogecoin.
2. Replace hash placeholders.
3. Chạy BitML compiler để xuất `.balzac`.
4. Chạy test cases (pytest) kiểm tra output và thống kê tài nguyên.

## Yêu cầu

- Có `docker` (host không cần cài `stack` hay `racket`).

## Chạy demo

Biên dịch 1 ứng dụng (ví dụ Donate receiver-chosen):

```bash
make compile EXAMPLE=ReceiverChosenDenomination
```

Biên dịch tất cả examples:

```bash
make compile-all
```

Kết quả nằm ở:

- `vendor/BitMLx/output/*.rkt` (BitML contracts dạng Racket)
- `vendor/BitMLx/output/*.balzac` (output từ BitML compiler)
- `vendor/BitMLx/output/*_depth.txt` (độ sâu cây thực thi)

## Test cases

```bash
make test
```

Các test tập trung vào 4 ứng dụng chính trong paper:

- `ReceiverChosenDenomination` (Donate)
- `TwoPartyAgreement` (DonateAgreed/coin-toss)
- `MultichainPaymentExchange` (Exchange service)
- `MultichainLoanMediator` (Loan + mediator)

## Web app

```bash
python web/app.py
```