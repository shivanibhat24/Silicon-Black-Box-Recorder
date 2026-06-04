# SBBR Register Map

All registers are 32-bit, word-addressed (4-byte aligned). APB address width = 12 bits.

## Register Summary

| Offset | Name          | R/W  | Description                                   |
|--------|---------------|------|-----------------------------------------------|
| 0x000  | STATUS        | RO   | System status (snapshot_valid, etc.)           |
| 0x004  | CONTROL       | RW   | Configuration: severity, rate limit, compress  |
| 0x008  | FAULT_STATUS  | R/W1C| Active fault vector (write-1-to-clear)         |
| 0x00C  | TRACE_HEAD    | RO   | Circular buffer head pointer                   |
| 0x010  | TRACE_TAIL    | RO   | Circular buffer tail pointer                   |
| 0x014  | SNAPSHOT_INFO | R/WA | Fault metadata; write any value to clear       |
| 0x018  | TS_LOW        | RO   | Current timestamp [31:0]                       |
| 0x01C  | TS_HIGH       | RO   | Current timestamp [47:32]                      |
| 0x020  | TRACE_DATA    | RO   | Streaming read port for trace buffer           |

## CONTROL Register (0x004)

| Bits   | Field            | Reset   | Description                            |
|--------|------------------|---------|----------------------------------------|
| [1:0]  | min_severity     | 2'b00   | Minimum event severity to record       |
| [2]    | delta_en         | 1'b1    | Enable delta-timestamp compression     |
| [3]    | dedup_en         | 1'b0    | Enable duplicate event suppression     |
| [4]    | zero_sup_en      | 1'b0    | Enable zero-payload suppression        |
| [15:8] | rate_limit       | 8'h01   | Max low-priority events per window     |
| [31:16]| rate_window      | 16'h0000| Rate-limit window size in cycles       |

## STATUS Register (0x000)

| Bits   | Field            | Description                            |
|--------|------------------|----------------------------------------|
| [1]    | snapshot_valid   | 1 = snapshot data ready for extraction |
| [31:2] | reserved         | Read as zero                           |

## FAULT_STATUS Register (0x008)

| Bits   | Field            | Description                            |
|--------|------------------|----------------------------------------|
| [0]    | voltage_droop    | Voltage droop fault                    |
| [1]    | overcurrent      | Overcurrent fault                      |
| [2]    | overtemp         | Over-temperature fault                 |
| [3]    | pll_unlock       | PLL unlock fault                       |
| [4]    | clk_fail         | Clock failure fault                    |
| [5]    | watchdog         | Watchdog timeout fault                 |
| [6]    | sensor_fault     | Sensor malfunction fault               |
| [7]    | user             | User-defined fault                     |
