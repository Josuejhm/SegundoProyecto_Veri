# Testplan
---
 
## 1. Test Base: `aligner_base_test`
 
Todos los estímulos se generan aleatoriamente respetando únicamente las restricciones del protocolo (MD y APB).
 
| Agente | Señal | Randomización |
|--------|-------|---------------|
| APB | `paddr` | Aleatorio sobre todo el espacio de 16 bits |
| APB | `pwrite` | Aleatorio |
| APB | `pwdata` | Aleatorio |
| APB | Delays entre transacciones | Aleatorios |
| MD RX | `md_rx_data` | Aleatorio |
| MD RX | `md_rx_offset` | Aleatorio (legales e ilegales) |
| MD RX | `md_rx_size` | Aleatorio (legales e ilegales) |
| MD RX | Delays entre transacciones | Aleatorios |
| MD TX | `md_tx_ready` | Aleatorio (backpressure variable) |
| MD TX | `md_tx_err` | Aleatorio, solo cuando `md_tx_valid && md_tx_ready` |
 
---
 
## 2. Corner Cases via Plusarg
 
Se activan con `+define+CORNER=<modo>`. Cada modo ajusta pesos o constraints del test base sin hardcodear valores.
 
| Modo | Descripción | Qué se sesga |
|------|-------------|--------------|
| `fifo_rx_full` | Presionar RX FIFO hasta llenarlo | Producer RX muy rápido, TX ready bajo frecuentemente |
| `fifo_tx_full` | Presionar TX FIFO hasta llenarlo | TX ready bajo por tiempos largos, RX producer moderado |
| `fifo_both_full` | Ambas FIFOs llenas simultáneamente | RX rápido + TX ready casi siempre bajo |
| `fifo_empty` | Mantener FIFOs vacías | RX producer lento, TX ready siempre alto |
| `illegal_rx` | Saturar CNT_DROP | Alta probabilidad de (offset, size) ilegales en RX |
| `cnt_sat` | Forzar CNT_DROP cerca de MAX | Mezcla de ilegales hasta rozar 255, luego algunos válidos |
| `apb_unmapped` | Ejercitar accesos a direcciones no mapeadas | `paddr` sesgado hacia zonas sin registro |
| `apb_illegal_ctrl` | Ejercitar combinaciones ilegales de CTRL | `pwdata` sesgado hacia SIZE/OFFSET inválidos |
| `irq_stress` | Todos los IRQs activos y limpiados repetidamente | IRQEN aleatorio, W1C frecuente mientras condición persiste |
| `backpressure` | Backpressure severo en TX | `md_tx_ready` bajo por ráfagas largas |

## 3. Covergroups
 
### 3.1 `cg_ctrl_config`
 
Cubre todas las combinaciones legales de `CTRL.SIZE` × `CTRL.OFFSET` escritas exitosamente. Las bins se recalculan en función de `ALGN_DATA_WIDTH`.
 
```
SIZE   ∈ {1, 2, 3, 4}
OFFSET ∈ {0, 1, 2, 3}
Cross  : SIZE × OFFSET (solo combinaciones legales según ALGN_DATA_WIDTH)
```
 
> La legalidad de una combinación está definida por: `((ALGN_DATA_WIDTH / 8) + OFFSET) % SIZE == 0`
 
---
 
### 3.2 `cg_rx_transfer`
 
Cubre el espacio de transferencias en la interfaz MD RX. Las bins de offset y size se recalculan en función de `ALGN_DATA_WIDTH`.
 
```
md_rx_size   ∈ {legal, ilegal}
md_rx_offset ∈ {legal, ilegal}
md_rx_err    ∈ {0, 1}
Cross        : (legal/ilegal) × md_rx_err
```
 
---
 
### 3.3 `cg_fifo_levels`
 
Cubre los niveles de llenado de ambas FIFOs. Las bins de "parcial" y "lleno" dependen de `FIFO_DEPTH`.
 
```
RX_LVL ∈ {vacío (0), parcial (1 a DEPTH-1), lleno (DEPTH)}
TX_LVL ∈ {vacío (0), parcial (1 a DEPTH-1), lleno (DEPTH)}
Cross  : RX_LVL × TX_LVL
```
 
---
 
### 3.4 `cg_cnt_drop`
 
Cubre los estados del contador de drops.
 
```
CNT_DROP ∈ {0, entre 1 y 254, 255 (MAX)}
CTRL.CLR escrito con 1 mientras CNT_DROP > 0
CTRL.CLR escrito con 1 mientras CNT_DROP == 0
```
 
---
 
### 3.5 `cg_apb_access`
 
Cubre todos los tipos de acceso APB por registro.
 
```
Registro     ∈ {CTRL, STATUS, IRQEN, IRQ, no_mapeado}
Tipo         ∈ {read, write}
pslverr      ∈ {0, 1}
Cross        : Registro × Tipo × pslverr
paddr[1:0]   ∈ {00, 01, 10, 11} para cada registro mapeado
```
 
---
 
### 3.6 `cg_irq`
 
Cubre el comportamiento de cada IRQ individualmente y en combinación.
 
```
Por cada IRQ ∈ {RX_FIFO_EMPTY, RX_FIFO_FULL, TX_FIFO_EMPTY, TX_FIFO_FULL, MAX_DROP}:
  - IRQ seteado con IRQEN=1  → irq=1
  - IRQ seteado con IRQEN=0  → irq=0
  - W1C mientras condición persiste  (IRQ no se re-setea inmediatamente)
  - W1C mientras condición ya no existe (IRQ no vuelve hasta próximo evento)
Cross: múltiples IRQs activos simultáneamente
```
 
---
 
### 3.7 `cg_backpressure`
 
Cubre el comportamiento del protocolo MD bajo backpressure.
 
```
md_tx_ready bajo por     ∈ {1 ciclo, 2-5 ciclos, >5 ciclos}
md_rx_ready bajo (DUT)     cuando RX FIFO lleno ∈ {observado, no observado}
md_tx_err=1 durante handshake válido            ∈ {observado, no observado}
```
 
---
 
## 4. Parámetros de Elaboración
 
Para cada combinación de valores, el testplan completo debe ejecutarse con múltiples semillas hasta alcanzar cobertura completa.
 
| Parámetro | Valores | Impacto |
|-----------|---------|---------|
| `ALGN_DATA_WIDTH` | `{8, 16, 32 (default), 64}` | Ancho de data bus, rango legal de offset/size, bins de `cg_ctrl_config` y `cg_rx_transfer` |
| `FIFO_DEPTH` | `{2 (mínimo), 8 (default), 16}` | Valores máximos de RX_LVL y TX_LVL, bins de `cg_fifo_levels` |