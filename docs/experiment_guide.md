# Hướng Dẫn Thí Nghiệm Chi Tiết: Toolchain BitMLx/BitML

Tài liệu này hướng dẫn từng bước thực hiện các thí nghiệm trên hệ thống biên dịch và trực quan hóa smart contract cross-chain BitMLx/BitML. Mỗi thí nghiệm đi kèm câu hỏi nghiên cứu (RQ), các bước thực hiện cụ thể, kết quả kỳ vọng và cách đối chiếu với artifacts đã sinh.

---

## Mục lục

1. Thiết lập môi trường
2. Tổng quan các câu hỏi nghiên cứu
3. Thí nghiệm 1 — Biên dịch và xác minh tính đúng đắn (RQ1)
4. Thí nghiệm 2 — Phân tích kích thước artifacts (RQ2)
5. Thí nghiệm 3 — Đo độ phức tạp pipeline cross-chain (RQ3)
6. Thí nghiệm 4 — Web app và chức năng Try Contract (RQ4)
7. Thí nghiệm 5 — Step secrets và priority choice (RQ5)
8. Thí nghiệm 6 — Tính nhất quán giữa Bitcoin và Dogecoin (RQ6)
9. Thí nghiệm 7 — Mở rộng với contract tự định nghĩa (RQ7)
10. Xử lý sự cố
11. Mẫu báo cáo kết quả

---

## 1. Thiết lập môi trường

### 1.1. Yêu cầu phần cứng

- CPU 4 nhân trở lên
- RAM tối thiểu 8 GB; khuyến nghị 16 GB khi compile `MultichainLoanMediator`
- Dung lượng trống ít nhất 10 GB cho Docker image, Stack cache và Racket package
- Kết nối Internet ổn định cho lần build đầu tiên

### 1.2. Yêu cầu phần mềm

- Docker Engine hoặc Docker Desktop (phiên bản 24.x trở lên)
- Git để clone repository
- Python 3.11+ (chỉ cần ở host khi chạy web app; toolchain bên trong container)
- GNU Make (mặc định trên Linux/macOS)

### 1.3. Cài đặt và chuẩn bị

```bash
# Clone repository
git clone <repository-url> BitMLx
cd BitMLx

# Build Docker image (lần đầu mất 5-10 phút)
make docker-build

# Xác minh image đã build thành công
docker images | grep blockchain-bitmlx
```

### 1.4. Khởi tạo môi trường bên trong container

```bash
make bootstrap
```

Lệnh này chạy `scripts/bootstrap.sh` để:

- Tạo Python venv tại `/home/user/.local/venv`
- Cài `prettytable` và `pytest`
- Cài BitML compiler vào Racket qua `raco pkg install`
- Chạy `stack setup && stack build` cho BitMLx compiler

Lần đầu có thể mất 10–15 phút vì Stack tải GHC. Các lần sau cache nằm trong named volume `blockchain_bitmlx_stack`.

---

## 2. Tổng quan các câu hỏi nghiên cứu

| RQ | Nội dung câu hỏi | Thí nghiệm |
|----|------------------|-----------|
| RQ1 | Toolchain có biên dịch chính xác mọi hợp đồng BitMLx mẫu không? | TN1 |
| RQ2 | Kích thước artifacts thay đổi thế nào theo độ phức tạp hợp đồng? | TN2 |
| RQ3 | Số transaction và depth của BitML output tăng theo quy luật nào? | TN3 |
| RQ4 | Web app có hỗ trợ trực quan hóa và biên dịch contract tùy biến không? | TN4 |
| RQ5 | Cơ chế step secrets và priority choice ảnh hưởng artifacts ra sao? | TN5 |
| RQ6 | Bitcoin và Dogecoin output có nhất quán cấu trúc không? | TN6 |
| RQ7 | Hệ thống có chịu được contract tùy biến với deposit lớn không? | TN7 |

---

## 3. Thí nghiệm 1 — Biên dịch và xác minh tính đúng đắn (RQ1)

**Mục tiêu:** xác nhận toolchain biên dịch thành công 4 hợp đồng mẫu và artifacts khớp với giá trị kỳ vọng.

### 3.1. Các bước thực hiện

```bash
# Biên dịch từng ứng dụng
make compile EXAMPLE=ReceiverChosenDenomination
make compile EXAMPLE=TwoPartyAgreement
make compile EXAMPLE=MultichainPaymentExchange
make compile EXAMPLE=MultichainLoanMediator

# Hoặc biên dịch toàn bộ trong một lệnh
make compile-all
```

### 3.2. Xác minh tự động

```bash
make test
```

Lệnh này chạy `tests/test_bitmlx_pipeline.py` bằng pytest. Mỗi test biên dịch một contract và đối chiếu:

- File `<App>_bitcoin.balzac`, `<App>_dogecoin.balzac`, `<App>_depth.txt` đã tồn tại
- Số transaction lớn nhất trong file `.balzac` khớp giá trị kỳ vọng
- Depth trong `_depth.txt` khớp giá trị kỳ vọng

### 3.3. Giá trị kỳ vọng

| Ứng dụng | Transactions | Depth |
|----------|-------------:|------:|
| ReceiverChosenDenomination | 51 | 6 |
| TwoPartyAgreement | 51 | 6 |
| MultichainPaymentExchange | 207 | 9 |
| MultichainLoanMediator | 4098 | 27 |

### 3.4. Tiêu chí thành công

- `make test` báo `4 passed`
- Output mỗi contract có đủ 6 file: 2 file `.rkt`, 2 file `.balzac`, 1 file `_depth.txt`, 1 phần trong `statistics.txt`

### 3.5. Cách đọc kết quả thủ công

```bash
# Xem statistics tổng hợp
cat vendor/BitMLx/output/statistics.txt

# Đếm transaction trong file .balzac của Bitcoin
grep -c "^transaction T" vendor/BitMLx/output/ReceiverChosenDenomination_bitcoin.balzac

# Xem depth
cat vendor/BitMLx/output/ReceiverChosenDenomination_depth.txt
```

---

## 4. Thí nghiệm 2 — Phân tích kích thước artifacts (RQ2)

**Mục tiêu:** đo kích thước file `.rkt` và `.balzac` của 4 contract, từ đó kiểm tra giả thuyết "độ phức tạp logic càng cao, artifacts tăng phi tuyến".

### 4.1. Các bước thực hiện

```bash
# Sau khi đã chạy compile-all, list kích thước các artifacts
find dist/bitmlx_artifacts -type f \( -name "*.rkt" -o -name "*.balzac" \) \
    -printf "%s\t%p\n" | sort -n
```

### 4.2. Kết quả kỳ vọng (đơn vị byte)

| Ứng dụng | Bitcoin .rkt | Dogecoin .rkt | Bitcoin .balzac | Dogecoin .balzac |
|----------|-------------:|--------------:|----------------:|-----------------:|
| ReceiverChosenDenomination | 6.326 | 6.328 | 15.631 | 15.635 |
| TwoPartyAgreement | 6.558 | 6.560 | 18.533 | 18.537 |
| MultichainPaymentExchange | 34.372 | 34.486 | 68.241 | 68.433 |
| MultichainLoanMediator | 1.145.845 | 1.145.977 | 1.265.684 | 1.264.787 |

### 4.3. Phân tích định lượng

Từ số liệu trên có thể rút ra:

- Tỷ lệ `.balzac/.rkt` dao động 1,1x đến 2,9x. Hai contract đầu có tỷ lệ ~2,5x, contract phức tạp ~1,1x.
- Kích thước `.rkt` của `MultichainLoanMediator` lớn gấp khoảng 33 lần `MultichainPaymentExchange`, dù số participant chỉ tăng từ 3 lên 3.
- Chênh lệch Bitcoin/Dogecoin < 0,1% → cấu trúc hai chain gần như đối xứng.

### 4.4. Tiêu chí thành công

- File `.balzac` luôn lớn hơn hoặc bằng file `.rkt` tương ứng (do `.balzac` mô tả chi tiết transactions UTXO).
- Tỷ lệ chênh lệch Bitcoin/Dogecoin < 1%.

---

## 5. Thí nghiệm 3 — Đo độ phức tạp pipeline cross-chain (RQ3)

**Mục tiêu:** xác định mối quan hệ giữa số participant, độ sâu cây hợp đồng (`PriorityChoice`, `Split`) và số transaction sinh ra.

### 5.1. Phương pháp

Sử dụng số liệu thu được từ TN1 và bảng `statistics.txt` để vẽ biểu đồ so sánh. Tham số khảo sát:

- Số participant (n)
- Depth gốc của BitMLx contract
- Depth của BitML output (sau khi compiler chuyển đổi)
- Số transaction tối đa

### 5.2. Bảng tổng hợp

| Ứng dụng | Participants | Depth (BitML) | Transactions |
|----------|-------------:|--------------:|-------------:|
| ReceiverChosenDenomination | 2 | 6 | 51 |
| TwoPartyAgreement | 2 | 6 | 51 |
| MultichainPaymentExchange | 3 | 9 | 207 |
| MultichainLoanMediator | 3 | 27 | 4098 |

### 5.3. Quan sát

- Khi tăng từ 2 lên 3 participant nhưng giữ logic đơn giản (Payment), số transaction tăng ~4 lần.
- Khi giữ 3 participant nhưng thêm `Split` lồng nhau và `Auth` của mediator (Loan), số transaction tăng gần 20 lần so với Payment.
- Depth tăng từ 9 → 27, gấp 3 lần, trong khi transaction tăng gấp ~20 → quan hệ phi tuyến.

### 5.4. Vẽ biểu đồ

Có thể dùng Python để xác nhận lại:

```bash
python3 - <<'PY'
import matplotlib.pyplot as plt
apps = ["RCD", "2Party", "Payment", "Loan"]
tx = [51, 51, 207, 4098]
depth = [6, 6, 9, 27]
fig, (a1, a2) = plt.subplots(1, 2, figsize=(10, 4))
a1.bar(apps, tx); a1.set_title("Transactions"); a1.set_yscale("log")
a2.bar(apps, depth); a2.set_title("Depth")
plt.tight_layout(); plt.savefig("/tmp/tn3.png", dpi=120)
print("/tmp/tn3.png")
PY
```

### 5.5. Tiêu chí thành công

- Sự tăng phi tuyến giữa độ sâu cây và số transaction được chứng minh bằng số liệu thực.
- Có biểu đồ minh họa lưu lại trong báo cáo.

---

## 6. Thí nghiệm 4 — Web app và chức năng Try Contract (RQ4)

**Mục tiêu:** kiểm tra giao diện web đọc đúng artifacts và chức năng `Try Contract` biên dịch được hợp đồng tùy biến.

### 6.1. Khởi chạy web app

```bash
# Trên host (không cần Docker)
python3 -m venv .venv
source .venv/bin/activate
pip install flask
python3 web/app.py
```

Truy cập:

- Dashboard: `http://localhost:5000/`
- Chi tiết: `http://localhost:5000/app/ReceiverChosenDenomination`
- Try Contract: `http://localhost:5000/try`

### 6.2. Kiểm tra dashboard

- Hiển thị đủ 4 thẻ ứng dụng
- Có biểu đồ so sánh transaction và depth
- Tổng số contract = 4, tổng transaction = 51 + 51 + 207 + 4098 = 4407

### 6.3. Kiểm tra trang chi tiết

- Hiển thị thông tin per-chain (Bitcoin, Dogecoin)
- Liệt kê đúng participants từ file `.rkt`
- Liệt kê secrets
- Cho phép expand/collapse nội dung `.rkt` và `.balzac`

### 6.4. Kiểm tra Try Contract

Kịch bản test cơ bản:

1. Chọn template `SimpleExchange`
2. Đổi tên participant `A` → `Alice`, `B` → `Bob`
3. Đổi deposit của Alice từ `(1, 0)` → `(5, 0)`, Bob từ `(0, 1)` → `(0, 5)`
4. Bấm `Compile`
5. Đợi kết quả

Tiêu chí pass:

- Status `success: true`
- Có file `.rkt` và `.balzac` cho cả Bitcoin và Dogecoin trong panel kết quả
- Số transaction hiển thị > 0
- Tên `Alice`, `Bob` xuất hiện trong source `.hs` được sinh ra
- Toàn bộ `((X, Y)` trong contract body được scale đúng tỷ lệ mới (5x)

### 6.5. Kịch bản test nâng cao

- Nhập tên có ký tự đặc biệt (`A!@#`): backend sanitize về `A`, không lỗi
- Để trống tên: backend dùng default `X`
- Nhập deposit âm hoặc 0 cho mọi participant: kỳ vọng compile fail với lỗi `NoDeposit` hoặc `InconsistentWithdraw`

### 6.6. Tiêu chí thành công

- Cả 5 template đều compile được với thông số mặc định
- Tên participant tùy biến không gây injection
- Path traversal `../../etc/passwd` bị chặn (route `/api/file`)

---

## 7. Thí nghiệm 5 — Step secrets và priority choice (RQ5)

**Mục tiêu:** quan sát số lượng và tên các step secret được sinh trong artifacts, đối chiếu với cây ưu tiên trong contract gốc.

### 7.1. Đếm số secret trong `.rkt`

```bash
for app in ReceiverChosenDenomination TwoPartyAgreement \
           MultichainPaymentExchange MultichainLoanMediator; do
  count=$(grep -c "secret" "vendor/BitMLx/output/${app}_bitcoin.rkt" || true)
  printf "%-30s %d\n" "$app" "$count"
done
```

### 7.2. Quan sát quy luật đặt tên

Step secret có dạng `StepSecret_<participant>__<moves>_<splits>` trong đó:

- `<moves>` là chuỗi `L`/`R` ghi lại nhánh trái/phải của các `PriorityChoice` đã đi qua
- `<splits>` ghi lại các nhánh `Split`

### 7.3. Bảng số liệu kỳ vọng

| Ứng dụng | Secrets/Bitcoin | Tỷ lệ secret/participant |
|----------|---------------:|-------------------------:|
| ReceiverChosenDenomination | 8 | 4 |
| TwoPartyAgreement | 10 | 5 |
| MultichainPaymentExchange | 12 | 4 |
| MultichainLoanMediator | 18 | 6 |

### 7.4. Tiêu chí thành công

- Số secret tăng theo độ sâu cây ưu tiên, không phải theo số participant.
- Mỗi nhánh `PriorityChoice` đều có ít nhất một step secret cho mỗi participant.

---

## 8. Thí nghiệm 6 — Tính nhất quán giữa Bitcoin và Dogecoin (RQ6)

**Mục tiêu:** chứng minh hai output BitML cho hai chain có cấu trúc gần như đối xứng.

### 8.1. So sánh số transaction

```bash
for app in ReceiverChosenDenomination TwoPartyAgreement \
           MultichainPaymentExchange MultichainLoanMediator; do
  btc=$(grep -c "^transaction T" "vendor/BitMLx/output/${app}_bitcoin.balzac")
  doge=$(grep -c "^transaction T" "vendor/BitMLx/output/${app}_dogecoin.balzac")
  printf "%-30s BTC=%d DOGE=%d\n" "$app" "$btc" "$doge"
done
```

### 8.2. So sánh depth

```bash
for f in vendor/BitMLx/output/*_depth.txt; do
  printf "%-50s %s\n" "$(basename "$f")" "$(cat "$f")"
done
```

### 8.3. So sánh structural diff

```bash
for app in ReceiverChosenDenomination TwoPartyAgreement \
           MultichainPaymentExchange MultichainLoanMediator; do
  diff <(sed 's/bitcoin/CHAIN/g; s/btc/COIN/g' \
            "vendor/BitMLx/output/${app}_bitcoin.rkt") \
       <(sed 's/dogecoin/CHAIN/g; s/doge/COIN/g' \
            "vendor/BitMLx/output/${app}_dogecoin.rkt") \
    | head -20
  echo "---"
done
```

### 8.4. Tiêu chí thành công

- Số transaction Bitcoin và Dogecoin bằng nhau cho mọi contract
- Depth Bitcoin và Dogecoin bằng nhau
- Diff giữa 2 file `.rkt` (sau khi normalize tên chain) chỉ khác ở giá trị coin, không khác cấu trúc

---

## 9. Thí nghiệm 7 — Mở rộng với contract tự định nghĩa (RQ7)

**Mục tiêu:** kiểm tra hệ thống chịu được hợp đồng tùy biến với deposit lớn (>1000) và participant nhiều hơn.

### 9.1. Tạo contract tùy biến qua Try Contract

1. Truy cập `http://localhost:5000/try`
2. Chọn `MultichainPaymentExchange`
3. Đổi deposit:
   - Customer: `(1000, 0)`
   - Receiver: `(0, 0)`
   - Exchange: `(0, 10000)`
4. Bấm `Compile`

### 9.2. Kết quả kỳ vọng

- Compile thành công, không lỗi `InconsistentWithdraw` (nhờ scaling tự động)
- Số transaction xấp xỉ 207 (giữ nguyên cấu trúc)
- File `.balzac` size không tăng đáng kể (chỉ tăng vài byte do số chữ số coin lớn hơn)

### 9.3. Test stress với contract phức tạp nhất

```bash
# Đo thời gian compile MultichainLoanMediator
time make compile EXAMPLE=MultichainLoanMediator
```

Trên máy 16 GB RAM, kỳ vọng:

- Tổng thời gian compile (sau lần đầu) < 60 giây
- Peak memory của `racket` < 4 GB
- Output `.balzac` ~1,2 MB cho mỗi chain

### 9.4. Tiêu chí thành công

- Mọi biến thể deposit (1, 100, 10000) đều compile thành công
- Pipeline không phụ thuộc giá trị deposit cụ thể, chỉ phụ thuộc cấu trúc cây hợp đồng

---

## 10. Xử lý sự cố

| Vấn đề | Triệu chứng | Giải pháp |
|--------|-------------|-----------|
| Docker build thất bại | `failed to fetch` | Kiểm tra mạng, retry; xác nhận có quyền tải image `debian:bookworm-slim` |
| `bpf_prog_query(BPF_CGROUP_DEVICE) failed` | Lỗi runc/cgroup trên kernel custom (WSL2) | Đã thêm `--privileged --cgroupns=host` vào `scripts/docker_run.sh` |
| Stack build chậm | Lần đầu mất 10–15 phút | Bình thường: tải GHC ~200 MB và build dependency |
| Racket compile error | `module not found: bitml` | Chạy `make bootstrap` trước, đảm bảo `raco pkg install` đã chạy |
| Web app 500 error | Trang detail trả về lỗi | Kiểm tra `dist/bitmlx_artifacts/<App>/` có đủ file không; chạy `make compile-all` |
| `MultichainLoanMediator` timeout | Quá 5 phút không xong | Tăng timeout trong `web/app.py` `subprocess.run(..., timeout=600)` |
| Tên participant trùng nhau | Compile fail | Sanitize đã khử ký tự đặc biệt nhưng không khử trùng; nhập tên khác nhau |
| Volume permission denied | `chown` fail | Xóa volume cũ: `docker volume rm blockchain_bitmlx_local blockchain_bitmlx_stack` |

---

## 11. Mẫu báo cáo kết quả

Khi hoàn tất các thí nghiệm, tổng hợp số liệu vào bảng sau để báo cáo:

```text
TN1 — Biên dịch và xác minh (RQ1)
  - 4 contract compile thành công: [✓/✗]
  - pytest passed: [4/4]

TN2 — Kích thước artifacts (RQ2)
  - File .balzac/.rkt ratio: [đo được]
  - Bitcoin/Dogecoin diff: [đo được]

TN3 — Độ phức tạp pipeline (RQ3)
  - Quan hệ depth-transaction: [tuyến tính/phi tuyến]
  - Biểu đồ: [đường dẫn file]

TN4 — Web app và Try Contract (RQ4)
  - Dashboard hiển thị đúng: [✓/✗]
  - 5 template compile thành công: [số lượng pass]

TN5 — Step secrets (RQ5)
  - Số secret theo từng app: [bảng]

TN6 — Bitcoin vs Dogecoin (RQ6)
  - Cấu trúc nhất quán: [✓/✗]

TN7 — Contract tùy biến (RQ7)
  - Coin scaling hoạt động: [✓/✗]
  - Stress test pass: [✓/✗]
```

### 11.1. Đính kèm trong báo cáo cuối

- Ảnh chụp dashboard web app
- Ảnh chụp trang Try Contract sau khi compile thành công
- Bảng `statistics.txt`
- File log `make test`
- Biểu đồ so sánh giữa 4 contract

---

## Phụ lục A — Cấu trúc thư mục artifacts

```
dist/bitmlx_artifacts/
├── ReceiverChosenDenomination/
│   ├── ReceiverChosenDenomination_bitcoin.rkt
│   ├── ReceiverChosenDenomination_bitcoin.balzac
│   ├── ReceiverChosenDenomination_dogecoin.rkt
│   ├── ReceiverChosenDenomination_dogecoin.balzac
│   └── ReceiverChosenDenomination_depth.txt
├── TwoPartyAgreement/
├── MultichainPaymentExchange/
└── MultichainLoanMediator/
```

## Phụ lục B — Lệnh tóm tắt

| Mục đích | Lệnh |
|----------|------|
| Build Docker | `make docker-build` |
| Bootstrap toolchain | `make bootstrap` |
| Compile 1 contract | `make compile EXAMPLE=<Tên>` |
| Compile tất cả | `make compile-all` |
| Chạy test | `make test` |
| Dọn output | `make clean` |
| Chạy web app | `python3 web/app.py` |
