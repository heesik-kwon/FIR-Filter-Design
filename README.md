# 🎛️ RRC FIR Filter (Pipeline Optimized)
> System Verilog로 33탭 Root Raised Cosine (RRC) FIR 필터를 설계하고, 파이프라인 구조를 적용하여  
> **Setup Violation**을 해소하고 **Timing Closure**를 달성한 FIR 필터 구현 프로젝트입니다.

---

# 📌 프로젝트 개요

| 항목             | 내용                                                   |
|------------------|--------------------------------------------------------|
| **⏱️ 수행 기간** | 2024.07.15 ~ 2024.07.17                               |
| **🖥️ 개발 환경**  | Vivado, VCS, VSCode                               |
| **📦 플랫폼**     | Basys3 Board                          |
| **💻 언어**       | System Verilog                                           |
| **📊 검증 방식**  | RTL Simulation, MATLAB Golden Vector 비교, Timing Report 분석 |

---

# 🎯 주요 기능

- ⚙️ **33탭 RRC FIR 필터 구현**  
  - 입력: signed `<1.6>` 형식 (7bit)  
  - 계수: 최대 ±196, 대칭 구조 적용  
  - 출력: signed `<1.6>` 포맷으로 포화 처리(Saturation)

- 📈 **파이프라인 최적화**  
  - 곱셈 → 부분합 → 최종합 → 시프트(>>8) → 포화 단계를 각각 파이프라인 레지스터로 분리  
  - Critical Path를 3단으로 나눠 Setup Slack 개선  
  - 레이턴시: 3 cycles → 5 cycles (+2 cycles)  
---

# 📉 RTL 시뮬레이션 결과
아래 이미지는 동일한 입력 벡터(`input_vector.txt`)를 적용했을 때의 RTL 시뮬레이션 파형 비교입니다.  

**상단:** 파이프라인 적용 전 / **하단:** 파이프라인 적용 후

<img width="800" alt="image" src="https://github.com/user-attachments/assets/c3de5553-40f7-4e74-9967-7c4328e540eb" />

### 관찰 포인트
- **레이턴시 증가**
   - 동일 입력 이벤트(빨간 점선 기준)에서 출력이 유효해지기까지의 사이클 수가 증가
   - 적용 전: 약 **3 cycles**  
   - 적용 후: 약 **5 cycles**  
   → 파이프라인 레지스터 추가로 인해 레이턴시가 **+2 cycles** 증가

- **출력 데이터 일치**
   - 레이턴시 보정 후, 적용 전/후 출력이 **일치**
   - 기능적 동작에는 변화 없음

<img width="800" alt="image" src="https://github.com/user-attachments/assets/0c8b9aa1-9439-4ef5-9664-583ca6771ddb" />

---

# ⏱️ 타이밍 분석 (Setup Violation → Timing Closure)

아래 이미지는 **동일 FIR 필터**를 **파이프라인 적용 전(좌)** /  **적용 후(우)** 로 합성한 타이밍 리포트 비교입니다.

<img width="800" alt="image" src="https://github.com/user-attachments/assets/5a622ec7-0d0f-4642-b503-c67bba8464b2" />

- **좌측 (적용 전)**  
  - Startpoint → Endpoint 경로에 곱셈 + 전체 합산 + 시프트 + 포화가 한 사이클에 몰림  
  - Worst Setup Slack = **-28.73 ns** → **Setup Violation 발생**
- **우측 (적용 후)**  
  - 최종합, 시프트, 포화를 **각각 파이프라인 레지스터로 분리**  
  - Critical Path Delay가 크게 줄어 Worst Setup Slack = **+15.56 ns** → **Timing Closure 달성**

**정리:** 파이프라인 단을 추가하여 크리티컬 패스를 3단으로 나누면서 타이밍 여유가 확보

