# SBBR Fault Scenarios

## Scenario 1: Voltage Droop
- **Trigger**: Voltage drops below DROOP_TH_MV (810 mV default)
- **Expected**: EVT_VOLTAGE_DROOP with SEV_CRITICAL, fault_voltage_droop asserted
- **Verification**: Check trace buffer contains droop event, snapshot triggers on fatal escalation

## Scenario 2: Thermal Runaway
- **Trigger**: Temperature rises through WARN_TEMP_C (85°C) then exceeds CRIT_TEMP_C (105°C)
- **Expected**: First EVT_TEMP_WARNING (SEV_WARNING), then EVT_OVERTEMP (SEV_FATAL)
- **Verification**: Both events captured in trace, fault_overtemp triggers snapshot

## Scenario 3: PLL Unlock
- **Trigger**: PLL loses lock after acquisition
- **Expected**: EVT_PLL_UNLOCK with SEV_FATAL
- **Verification**: Trace frozen, snapshot metadata shows FLT_PLL_UNLOCK

## Scenario 4: Clock Failure
- **Trigger**: Clock stops or frequency anomaly detected
- **Expected**: EVT_CLK_FAIL with SEV_FATAL
- **Verification**: Immediate freeze, fault_clk_fail in fault vector

## Scenario 5: Watchdog Timeout
- **Trigger**: Watchdog timer expires (external assertion)
- **Expected**: fault_watchdog asserted after debounce
- **Verification**: Fault vector bit 5 set, fatal pulse generated

## Scenario 6: Sensor Malfunction
- **Trigger**: Sensor returns out-of-range or CRC error
- **Expected**: fault_sensor_fault asserted
- **Verification**: EVT_SENSOR_FAULT event in trace buffer

## Scenario 7: Simultaneous Multi-Fault
- **Trigger**: Voltage droop + overtemperature simultaneously
- **Expected**: Both fault bits set in fault_vector, single fatal pulse
- **Verification**: Snapshot metadata shows both faults, trace contains both events

## Scenario 8: Buffer Saturation
- **Trigger**: Sustained high-rate event injection exceeding buffer capacity
- **Expected**: Circular buffer overwrites oldest entries, head pointer advances
- **Verification**: Verify data integrity of most recent entries after wraparound

## Scenario 9: Fault → Clear → Re-fault
- **Trigger**: Fault fires, SW clears via APB, same fault fires again
- **Expected**: Second snapshot captures new metadata
- **Verification**: Two distinct snapshots with different timestamps
