# Tài liệu kỹ thuật: BitMLx Artifacts Viewer -- Web Application

## Mục lục

1. [Tổng quan](#1-tổng-quan)
2. [Kiến trúc hệ thống](#2-kiến-trúc-hệ-thống)
3. [Cấu trúc thư mục](#3-cấu-trúc-thư-mục)
4. [Backend -- Flask Application](#4-backend----flask-application)
   - 4.1. Khởi tạo và cấu hình
   - 4.2. Các hàm phân tích dữ liệu (parser)
   - 4.3. Route hệ thống
   - 4.4. Tính năng Try Contract
5. [Frontend -- Giao diện người dùng](#5-frontend----giao-diện-người-dùng)
   - 5.1. Trang Dashboard (index.html)
   - 5.2. Trang Chi tiết (detail.html)
   - 5.3. Trang Try Contract (try.html)
6. [Quy trình biên dịch qua Docker](#6-quy-trình-biên-dịch-qua-docker)
7. [Hướng dẫn triển khai](#7-hướng-dẫn-triển-khai)
8. [Hạn chế và lưu ý bảo mật](#8-hạn-chế-và-lưu-ý-bảo-mật)

---

## 1. Tổng quan

BitMLx Artifacts Viewer là ứng dụng web được xây dựng bằng Flask (Python), cung cấp giao diện trực quan để:

- **Xem kết quả biên dịch** của 4 ứng dụng smart contract cross-chain đã được biên dịch sẵn qua BitMLx pipeline.
- **Thử nghiệm biên dịch** contract mới bằng cách chọn template có sẵn, tùy chỉnh tham số (tên participant, số lượng deposit BTC/DOGE), rồi gọi pipeline biên dịch thực tế qua Docker container.

Ứng dụng đọc dữ liệu trực tiếp từ thư mục artifacts đã sinh (`dist/bitmlx_artifacts/`) và hiển thị các chỉ số thống kê, nội dung file `.rkt` (BitML contract), file `.balzac` (mô tả giao dịch UTXO), cùng metadata như danh sách participant, step secrets, và thông tin per-chain.

**Công nghệ sử dụng:**

| Thành phần | Công nghệ |
|------------|-----------|
| Backend | Python 3, Flask |
| Frontend | HTML, CSS, JavaScript (vanilla, không framework) |
| Template engine | Jinja2 (tích hợp sẵn trong Flask) |
| Biên dịch contract | Docker container chứa Haskell Stack + Racket |

---

## 2. Kiến trúc hệ thống

Hệ thống hoạt động theo mô hình sau:

```
Browser (user)
    |
    |  HTTP request
    v
Flask server (web/app.py, port 5000)
    |
    |-- GET /              --> Đọc dist/bitmlx_artifacts/, render dashboard
    |-- GET /app/<name>    --> Đọc artifacts của 1 app, render chi tiết
    |-- GET /try           --> Render form chọn template
    |-- POST /try/compile  --> Sinh file .hs --> Docker pipeline --> trả JSON
            |
            v
    Docker container (blockchain-bitmlx:dev)
        |
        |-- stack run (BitMLx compiler, Haskell)
        |       |
        |       v
        |   output/*.rkt (BitML contracts)
        |
        |-- replace_hash.py
        |-- racket *.rkt --> output/*.balzac
        |-- read_statistics.py --> output/statistics.txt
```

Luồng dữ liệu chính:

1. **Chế độ xem (Dashboard, Detail):** Flask đọc file tĩnh từ `dist/bitmlx_artifacts/`, phân tích nội dung, truyền dữ liệu vào Jinja2 template để render HTML.
2. **Chế độ thử nghiệm (Try Contract):** Frontend gửi JSON chứa tham số tới `/try/compile`. Backend sinh mã Haskell, gọi Docker container chạy full pipeline, thu thập kết quả và trả về JSON cho frontend hiển thị.

---

## 3. Cấu trúc thư mục

```
web/
  app.py                  # Flask application (backend)
  templates/
    index.html            # Trang Dashboard
    detail.html           # Trang chi tiết từng contract
    try.html              # Trang Try Contract (form + kết quả)
```

Các thư mục liên quan:

```
dist/bitmlx_artifacts/    # Artifacts đã biên dịch sẵn (đầu vào cho Dashboard)
  ReceiverChosenDenomination/
  TwoPartyAgreement/
  MultichainPaymentExchange/
  MultichainLoanMediator/

vendor/BitMLx/            # BitMLx compiler source (Haskell)
  app/Examples/*.hs       # Template contract gốc (đầu vào cho Try Contract)
  app/Main.hs             # Entry point của compiler
  output/                 # Thư mục đầu ra khi chạy pipeline

scripts/
  docker_run.sh           # Script khởi chạy Docker container
  bitmlx_pipeline.sh      # Pipeline biên dịch end-to-end
```

---

## 4. Backend -- Flask Application

Toàn bộ logic backend nằm trong file `web/app.py`. Phần dưới đây trình bày chi tiết từng thành phần.

### 4.1. Khởi tạo và cấu hình

```python
app = Flask(__name__)

ARTIFACTS_DIR = Path(__file__).resolve().parent.parent / "dist" / "bitmlx_artifacts"
PROJECT_ROOT = Path(__file__).resolve().parent.parent
DOCKER_IMAGE = os.environ.get("BITMLX_DOCKER_IMAGE", "blockchain-bitmlx:dev")
```

- `ARTIFACTS_DIR`: đường dẫn tuyệt đối tới thư mục chứa artifacts đã biên dịch. Được tính tương đối từ vị trí file `app.py`, đảm bảo hoạt động đúng bất kể thư mục hiện hành khi khởi chạy.
- `PROJECT_ROOT`: thư mục gốc của toàn bộ project, dùng để truy cập vendor source và scripts.
- `DOCKER_IMAGE`: tên Docker image, mặc định `blockchain-bitmlx:dev`, có thể ghi đè qua biến môi trường `BITMLX_DOCKER_IMAGE`.

**Dictionary `APPS_INFO`** lưu metadata của 4 ứng dụng chính (title, description bằng tiếng Việt), dùng để hiển thị trên Dashboard và validate request tới trang chi tiết.

### 4.2. Các hàm phân tích dữ liệu (parser)

#### `parse_statistics(stats_path: Path) -> dict | None`

Phân tích file `statistics.txt` do `read_statistics.py` sinh ra. File này có dạng bảng ASCII:

```
+----------------------------+------------------------------+...
|       Contract name        | Total Number of Transactions |...
+----------------------------+------------------------------+...
| ReceiverChosenDenomination |              51              |...
+----------------------------+------------------------------+...
```

Hàm lọc các dòng bắt đầu bằng `|`, tách ô theo ký tự `|`, và trích xuất 4 trường: tên contract, số transaction, depth, và thời gian biên dịch.

```python
lines = [l.strip() for l in text.splitlines() if l.strip().startswith("|")]
data_line = lines[-1]
cells = [c.strip() for c in data_line.split("|") if c.strip()]
```

Dòng cuối cùng trong danh sách các dòng `|` chính là dòng dữ liệu (dòng đầu là header). Mỗi ô được `.strip()` để loại bỏ khoảng trắng padding.

#### `parse_balzac_transactions(balzac_path: Path) -> int`

Đếm số transaction tối đa trong file `.balzac` bằng regex:

```python
matches = re.findall(r"transaction\s+T(\d+)", text)
return max(int(m) for m in matches)
```

File `.balzac` chứa các khai báo transaction dạng `transaction T1`, `transaction T2`, ..., `transaction T51`. Hàm tìm tất cả chỉ số và lấy giá trị lớn nhất, tức tổng số transaction được sinh ra.

#### `parse_rkt_participants(rkt_path: Path) -> list[str]`

Trích xuất tên participant từ file `.rkt` (BitML contract dạng Racket):

```python
re.findall(r'\(participant\s+"(\w+)"', text)
```

File `.rkt` khai báo participant theo cú pháp `(participant "A" "pkA")`. Regex bắt tên participant (nhóm `(\w+)` đầu tiên sau keyword `participant`).

#### `parse_rkt_secrets(rkt_path: Path) -> list[str]`

Trích xuất tên secret từ file `.rkt`:

```python
re.findall(r'\(secret\s+"[^"]+"\s+(\w+)', text)
```

Cú pháp secret trong `.rkt`: `(secret "A" StepSecret_A__L_ "hash...")`. Regex bỏ qua tên participant (`"[^"]+"`) và bắt tên secret (`(\w+)`).

#### `get_app_data(app_name: str) -> dict | None`

Hàm tổng hợp: gom tất cả dữ liệu của một ứng dụng thành một dictionary duy nhất. Quy trình:

1. Kiểm tra thư mục `dist/bitmlx_artifacts/<app_name>/` có tồn tại.
2. Gọi `parse_statistics()` để lấy thống kê.
3. Đọc file `*_depth.txt` để lấy depth.
4. Lặp qua 2 chain (bitcoin, dogecoin), cho mỗi chain thu thập: trạng thái file, kích thước, số transaction, danh sách participant, danh sách secret.

Kết quả trả về có cấu trúc:

```python
{
    "name": "ReceiverChosenDenomination",
    "info": {"title": "...", "description": "..."},
    "stats": {"transactions": 51, "depth": 6, "time": "51"},
    "depth": 6,
    "chains": {
        "bitcoin": {"rkt_size": 1234, "balzac_size": 5678, "tx_count": 51, ...},
        "dogecoin": {...},
    },
}
```

#### `read_file_content(app_name: str, filename: str) -> str | None`

Đọc nội dung file artifact, có kiểm tra path traversal:

```python
if not file_path.resolve().is_relative_to(ARTIFACTS_DIR.resolve()):
    return None
```

Dòng này đảm bảo đường dẫn sau khi resolve (xử lý `..`, symlink) vẫn nằm trong `ARTIFACTS_DIR`. Nếu ai đó truyền `filename` dạng `../../etc/passwd`, hàm sẽ trả `None` thay vì đọc file nhạy cảm.

### 4.3. Route hệ thống

#### `GET /` -- Dashboard

```python
@app.route("/")
def index():
    apps = []
    for name in APPS_INFO:
        data = get_app_data(name)
        if data:
            apps.append(data)
    return render_template("index.html", apps=apps)
```

Lặp qua 4 ứng dụng trong `APPS_INFO`, gom dữ liệu từng app bằng `get_app_data()`, truyền danh sách vào template `index.html`.

#### `GET /app/<app_name>` -- Chi tiết

```python
@app.route("/app/<app_name>")
def app_detail(app_name):
    if app_name not in APPS_INFO:
        abort(404)
```

Validate `app_name` phải nằm trong danh sách cho phép. Sau đó đọc nội dung file `.rkt` và `.balzac` của cả 2 chain, truncate file lớn hơn 50KB để tránh trình duyệt bị quá tải:

```python
if len(rkt_content) > 50000:
    rkt_content = rkt_content[:50000] + f"\n\n... (truncated, full file: {len(rkt_content)} bytes)"
```

### 4.4. Tính năng Try Contract

Đây là phần phức tạp nhất của ứng dụng. Gồm 3 thành phần chính: định nghĩa template, sinh mã nguồn Haskell, và gọi Docker pipeline.

#### 4.4.1. Định nghĩa template (`TEMPLATES`)

Dictionary `TEMPLATES` mô tả 5 contract template, mỗi template gồm:

```python
"SimpleExchange": {
    "title": "Simple Exchange",
    "description": "...",
    "participants": [
        {"var": "pA", "name": "A", "pk": "pkA", "role": "Sender BTC",
         "btc": 1, "doge": 0},
        ...
    ],
    "has_secrets": False,
    "time_start": 1,
    "time_delta": 10,
},
```

- `var`: tên biến Haskell trong source gốc (dùng để tìm và thay thế).
- `name`, `pk`: tên participant và public key gốc.
- `role`: vai trò hiển thị trên giao diện (không ảnh hưởng logic).
- `btc`, `doge`: số lượng deposit mặc định trên mỗi chain.

#### 4.4.2. Sinh mã nguồn Haskell (`generate_hs_source`)

Hàm này đọc file `.hs` template gốc từ `vendor/BitMLx/app/Examples/` và thực hiện các bước patch:

**Bước 1 -- Đổi tên module:**

```python
source = source.replace(
    f"module Examples.{template_name}",
    "module Examples.UserCustom",
)
```

Module Haskell phải khớp tên file. Vì file output sẽ là `UserCustom.hs`, module name phải là `Examples.UserCustom`.

**Bước 2 -- Tính tỷ lệ scale:**

```python
old_total_btc = sum(v[0][0] for v in coin_map.values())
new_total_btc = sum(v[1][0] for v in coin_map.values())
```

Contract BitMLx yêu cầu tổng withdraw trên mỗi chain phải bằng tổng deposit. Nếu user thay đổi deposit (ví dụ từ 1 BTC lên 5 BTC), tất cả các withdraw amount trong contract body cũng phải scale theo tỷ lệ tương ứng. Hàm tính tổng deposit cũ và mới trên mỗi chain để làm hệ số nhân.

**Bước 3 -- Patch tên participant và deposit:**

```python
source = source.replace(
    f'pname = "{orig["name"]}", pk = "{orig["pk"]}"',
    f'pname = "{new_name}", pk = "{new_pk}"',
)
```

Tìm chính xác chuỗi khai báo participant trong constructor `P {pname = "A", pk = "pkA"}` và thay bằng giá trị mới. Tương tự cho dòng deposit.

**Bước 4 -- Scale coin tuple trong contract body:**

```python
source = re.sub(
    r"\(\((\d+),\s*(\d+)\)",
    lambda m: "((" + scale_coin_tuple(m)[1:],
    source,
)
```

Regex `\(\((\d+),\s*(\d+)\)` khớp với pattern `((X, Y)` -- đây là cú pháp coin tuple trong BitMLx DSL (ví dụ `((1, 0), pA)` nghĩa là phân bổ 1 BTC, 0 DOGE cho participant A). Lambda function nhân mỗi giá trị với tỷ lệ scale tương ứng.

**Hàm `_validate_name`** lọc tên participant chỉ giữ ký tự alphanumeric và giới hạn 20 ký tự, ngăn chặn injection vào mã Haskell:

```python
def _validate_name(s: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9]", "", s)
    return cleaned[:20] if cleaned else "X"
```

#### 4.4.3. Gọi Docker pipeline (`run_compile_in_docker`)

Hàm này thực hiện quy trình biên dịch qua Docker container. Đây là phần quan trọng nhất vì nó kết nối web app với toolchain thực.

**Bước 1 -- Ghi file và patch Main.hs:**

```python
custom_hs.write_text(hs_source)

patched_main = original_main
patched_main = patched_main.replace(
    "import qualified Examples.Escrow as Escrow",
    "import qualified Examples.Escrow as Escrow\n"
    "import qualified Examples.UserCustom as UserCustom",
)
patched_main = patched_main.replace(
    '("Escrow", Escrow.example)',
    '("Escrow", Escrow.example)\n'
    '            , ("UserCustom", UserCustom.example)',
)
main_hs.write_text(patched_main)
```

`Main.hs` là entry point của BitMLx compiler. Để compiler nhận biết module mới `UserCustom`, cần thêm dòng import và đăng ký vào danh sách example. Patch được thực hiện bằng string replacement tại vị trí cố định (sau dòng import Escrow và sau entry Escrow trong danh sách).

**Bước 2 -- Chạy Docker container:**

```python
docker_run = PROJECT_ROOT / "scripts" / "docker_run.sh"
cmd = f'IMAGE={shlex.quote(DOCKER_IMAGE)} {shlex.quote(str(docker_run))} "./scripts/bitmlx_pipeline.sh UserCustom"'
result = subprocess.run(
    cmd, shell=True, capture_output=True, text=True,
    timeout=timeout, cwd=str(PROJECT_ROOT),
)
```

Lệnh gọi `docker_run.sh` với tham số là lệnh cần chạy bên trong container. `docker_run.sh` mount thư mục project vào `/workspace`, chạy dưới user `user` (uid 1000), sử dụng named volumes cho cache. Pipeline `bitmlx_pipeline.sh UserCustom` chạy các bước: `stack run -- UserCustom` (biên dịch BitMLx sang BitML), `replace_hash.py` (thay placeholder hash), `racket` (biên dịch BitML sang .balzac), `read_statistics.py` (thống kê).

`shlex.quote()` đảm bảo tên image và đường dẫn script được escape đúng, tránh shell injection.

**Bước 3 -- Thu thập kết quả:**

```python
for f in sorted(output_dir.glob("UserCustom*")):
    content = f.read_text()
    files[f.name] = content

stats = parse_statistics(output_dir / "statistics.txt")
```

Sau khi Docker chạy xong, output nằm tại `vendor/BitMLx/output/UserCustom_*.{rkt,balzac}`. Hàm đọc tất cả file khớp pattern, cùng với statistics và depth.

**Bước 4 -- Dọn dẹp (finally block):**

```python
finally:
    main_hs.write_text(original_main)
    if custom_hs.exists():
        custom_hs.unlink()
```

Block `finally` đảm bảo rằng dù biên dịch thành công hay thất bại, `Main.hs` luôn được khôi phục về nội dung gốc và file `UserCustom.hs` tạm thời luôn bị xóa. Điều này tránh làm ảnh hưởng đến trạng thái của repository.

#### 4.4.4. Route `/try/compile` (POST)

```python
@app.route("/try/compile", methods=["POST"])
def try_compile():
    data = request.get_json()
```

Route nhận JSON từ frontend với cấu trúc:

```json
{
    "template": "SimpleExchange",
    "participants": [
        {"name": "Alice", "btc": 5, "doge": 0},
        {"name": "Bob", "btc": 0, "doge": 50}
    ]
}
```

Quy trình xử lý:

1. Validate `template` có trong `TEMPLATES`.
2. Validate số lượng participant khớp với template.
3. Ép kiểu deposit thành số nguyên không âm.
4. Gọi `generate_hs_source()` rồi `run_compile_in_docker()`.
5. Trả JSON chứa: `success`, `output` (compile log), `files` (nội dung các file output), `stats`, `depth`, `hs_source` (mã Haskell đã sinh).

Timeout biên dịch được đặt 300 giây (5 phút). Nếu vượt quá, trả HTTP 504.

---

## 5. Frontend -- Giao diện người dùng

Giao diện sử dụng dark theme với bảng màu CSS variables, responsive, không phụ thuộc framework JavaScript bên ngoài.

### 5.1. Trang Dashboard (`index.html`)

Trang chính hiển thị tổng quan toàn bộ kết quả biên dịch.

**Thanh thống kê tổng quan (Overview):**

```html
{% set total_tx = apps | map(attribute='stats')
    | selectattr('transactions', 'defined')
    | map(attribute='transactions') | list %}
<div class="value">{{ total_tx | sum }}</div>
```

Jinja2 filter chain: từ danh sách `apps`, trích xuất thuộc tính `stats`, lọc những app có trường `transactions`, lấy giá trị, chuyển thành list rồi tính tổng. Kết quả hiển thị tổng số transaction của tất cả contract (4407).

**Biểu đồ thanh ngang (Bar chart):**

```html
{% set max_tx = apps | ... | max %}
<div class="bar-fill tx"
     style="width: {{ (a.stats.transactions / max_tx * 100) | round(1) }}%">
```

Chiều rộng thanh được tính theo phần trăm so với giá trị lớn nhất, tạo ra biểu đồ so sánh trực quan. `MultichainLoanMediator` (4098 tx) chiếm 100% chiều rộng, các contract khác hiển thị tỷ lệ tương ứng.

**Card cho từng ứng dụng:**

Mỗi card hiển thị 3 chỉ số chính (transactions, depth, compile time), thông tin per-chain (kích thước file, số transaction), và metadata (participant, số secret). Card link tới trang chi tiết `/app/<name>`.

**Nút "Try Contract"** nằm trong header, dẫn tới trang `/try`.

### 5.2. Trang Chi tiết (`detail.html`)

Hiển thị toàn bộ thông tin của một contract cụ thể.

**Thông tin per-chain:**

```html
{% for chain, info in data.chains.items() %}
<div class="chain-section">
    <div class="chain-dot {{ chain }}"></div>
```

Mỗi chain (Bitcoin, Dogecoin) có section riêng hiển thị kích thước file `.rkt` và `.balzac`, số transaction tối đa, danh sách participant. Class CSS `chain-dot.bitcoin` và `chain-dot.dogecoin` sử dụng màu đặc trưng (cam cho Bitcoin, vàng cho Dogecoin).

**Trích xuất danh sách participant không trùng lặp:**

```html
{% set all_participants = [] %}
{% for chain, info in data.chains.items() %}
    {% for p in info.participants %}
        {% if p not in all_participants %}
            {% if all_participants.append(p) %}{% endif %}
        {% endif %}
    {% endfor %}
{% endfor %}
```

Jinja2 không có built-in set/unique cho biến tích lũy xuyên vòng lặp. Đoạn trên dùng `list.append()` trong biểu thức `{% if %}` (giá trị trả về `None` nên if luôn false, nhưng side effect `append` vẫn xảy ra) để xây dựng danh sách unique thủ công.

**File viewer (expand/collapse):**

```html
<div class="file-header" onclick="this.nextElementSibling.classList.toggle('open'); ...">
```

Click vào header toggle class `open` trên element kế tiếp (`.file-content`). CSS `.file-content` mặc định `display: none`, class `.open` chuyển thành `display: block`.

### 5.3. Trang Try Contract (`try.html`)

Trang phức tạp nhất, kết hợp frontend tương tác với backend biên dịch.

**Dữ liệu template được nhúng vào JavaScript:**

```html
<script>
const TEMPLATES = {{ templates | tojson }};
</script>
```

`tojson` filter của Jinja2 serialize dictionary Python `TEMPLATES` thành JSON hợp lệ, nhúng trực tiếp vào `<script>`. Cách này tránh phải gọi thêm API để lấy danh sách template.

**Hàm `selectTemplate(key)`:**

```javascript
function selectTemplate(key) {
    selectedTemplate = key;
    // Highlight card đã chọn
    document.querySelectorAll('.template-card').forEach(c => c.classList.remove('selected'));
    document.querySelector(`...`).classList.add('selected');

    // Sinh form input cho từng participant
    t.participants.forEach((p, i) => {
        row.innerHTML = `
            <input type="text" data-idx="${i}" data-field="name" value="${p.name}">
            <input type="number" data-idx="${i}" data-field="btc" value="${p.btc}">
            <input type="number" data-idx="${i}" data-field="doge" value="${p.doge}">
        `;
    });
}
```

Khi user click vào một template card, hàm này hiển thị section tham số với form input được sinh động. Mỗi input có `data-idx` (chỉ số participant) và `data-field` (trường dữ liệu) để hàm `gatherParams()` thu thập giá trị.

**Hàm `doCompile()` -- gọi API biên dịch:**

```javascript
async function doCompile() {
    btn.disabled = true;
    btnText.textContent = 'Compiling...';

    const resp = await fetch('/try/compile', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(gatherParams()),
    });
    const data = await resp.json();
```

Hàm async gửi POST request với JSON body tới `/try/compile`. Trong khi chờ (có thể tới vài phút với contract phức tạp), button bị disable và hiện spinner CSS animation. Sau khi nhận response, hiển thị kết quả gồm: banner thành công/lỗi, thống kê, compile log (trong `<details>` tag để không chiếm diện tích), và nội dung các file output.

**Hàm `escapeHtml(str)` -- chống XSS:**

```javascript
function escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}
```

Nội dung file `.rkt`, `.balzac`, `.hs` được chèn vào DOM qua `innerHTML`. Để tránh XSS (nội dung file có thể chứa `<script>` hoặc HTML tag), hàm này tạo element tạm, gán nội dung qua `textContent` (tự động escape), rồi lấy lại qua `innerHTML`.

---

## 6. Quy trình biên dịch qua Docker

Khi user nhấn "Compile" trên trang Try Contract, quy trình diễn ra như sau:

```
1. Frontend gửi POST /try/compile với JSON:
   {"template": "SimpleExchange", "participants": [...]}

2. Backend validate input

3. generate_hs_source():
   - Đọc vendor/BitMLx/app/Examples/SimpleExchange.hs
   - Đổi module name thành Examples.UserCustom
   - Thay tên participant, deposit amounts
   - Scale tất cả coin tuple theo tỷ lệ deposit mới/cũ
   - Trả về mã Haskell đã patch

4. run_compile_in_docker():
   a. Ghi UserCustom.hs vào vendor/BitMLx/app/Examples/
   b. Patch Main.hs thêm import + đăng ký UserCustom
   c. Gọi: docker_run.sh "bitmlx_pipeline.sh UserCustom"
      Bên trong Docker container:
        i.   stack run -- UserCustom   (BitMLx -> BitML .rkt)
        ii.  replace_hash.py *.rkt     (thay hash placeholder)
        iii. racket *.rkt > *.balzac   (BitML -> giao dịch UTXO)
        iv.  read_statistics.py        (sinh statistics.txt)
   d. Đọc output files: UserCustom_bitcoin.rkt, UserCustom_dogecoin.rkt,
      UserCustom_bitcoin.balzac, UserCustom_dogecoin.balzac,
      UserCustom_depth.txt, statistics.txt
   e. Restore Main.hs gốc, xóa UserCustom.hs

5. Backend trả JSON chứa kết quả

6. Frontend hiển thị thống kê và nội dung file
```

---

## 7. Hướng dẫn triển khai

**Yêu cầu:**

- Python 3.10+ với Flask đã cài đặt (`pip install flask`)
- Docker đã cài đặt và Docker image `blockchain-bitmlx:dev` đã build
- Bootstrap đã chạy trong container (dependencies Haskell và Racket đã compile)

**Khởi chạy:**

```bash
# Từ thư mục gốc project
python3 web/app.py
```

Server khởi động tại `http://0.0.0.0:5000` (debug mode). Truy cập qua trình duyệt:

- `http://localhost:5000/` -- Dashboard
- `http://localhost:5000/try` -- Try Contract

**Ghi chú:** Chế độ debug mode (`debug=True`) tự động reload khi file thay đổi. Trong môi trường production, nên sử dụng WSGI server (Gunicorn, uWSGI) và tắt debug mode.

---

## 8. Hạn chế và lưu ý bảo mật

**Hạn chế chức năng:**

- Tính năng Try Contract chỉ cho phép sửa tên participant và số lượng deposit. Cấu trúc logic contract (priority choice, split, reveal) được giữ nguyên từ template gốc.
- Biên dịch contract phức tạp (MultichainLoanMediator) có thể mất vài phút. Không có cơ chế queue -- nếu nhiều user compile cùng lúc, các request sẽ xử lý tuần tự do patch Main.hs.
- File output lớn (MultichainLoanMediator tạo file `.balzac` trên 1MB) bị truncate khi hiển thị trên giao diện.

**Lưu ý bảo mật:**

- Tên participant được sanitize bằng `_validate_name()`, chỉ giữ ký tự alphanumeric, ngăn injection vào mã Haskell.
- Path traversal được kiểm tra bằng `Path.is_relative_to()` trong `read_file_content()`.
- Nội dung file output được escape bằng `escapeHtml()` phía frontend trước khi chèn vào DOM.
- Docker container chạy dưới user không phải root (uid 1000), giới hạn quyền hệ thống.
- Ứng dụng không được thiết kế để expose ra internet. Nếu triển khai public, cần bổ sung rate limiting và xác thực.
