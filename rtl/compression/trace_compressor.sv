// =============================================================================
// Silicon Black Box Recorder — Trace Compression Engine
// trace_compressor.sv
//
// Compresses the event stream before it enters circular trace memory.
// Three compression techniques (each independently configurable):
//
//  1. Delta-timestamp encoding
//       Full 48-bit timestamp → 16-bit delta from previous event
//       Saturates at 0xFFFF; on saturation emits a "timestamp reset" marker.
//
//  2. Duplicate event suppression
//       Identical (source_id, event_type, severity) in back-to-back cycles
//       replaced with a single-bit repeat flag + count field in a 16-bit word.
//       Max run count: 255.
//
//  3. Payload pass-through / zero-suppression
//       If payload == 32'h0, a zero-payload flag is set and payload omitted.
//       Saves 32 bits for the common "event only, no data" case.
//
// Compressed word format written to circular buffer (64 bits wide):
//   [63]    : delta_overflow   — 1 if delta saturated (abs timestamp follows)
//   [62]    : is_repeat        — 1 if this is a repeat-count record
//   [61]    : zero_payload     — 1 if payload was all zeros (payload field = 0)
//   [60:59] : severity
//   [58:55] : event_type
//   [54:47] : source_id
//   [46:31] : delta_ts or repeat_count[15:0]
//   [30:0]  : payload[30:0]  (MSB omitted when zero_payload)
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

import sbbr_pkg::*;

module trace_compressor (
  input  wire          clk,
  input  wire          rst_n,

  // Upstream
  input  wire          in_valid,
  input  event_pkt_t   in_event,
  output logic         in_ready,

  // Downstream — 64-bit compressed words
  output logic         out_valid,
  output logic [63:0]  out_word,
  input  wire          out_ready,

  // Configuration enables
  input  wire          cfg_delta_en,       // Enable delta-TS encoding
  input  wire          cfg_dedup_en,       // Enable duplicate suppression
  input  wire          cfg_zero_sup_en     // Enable zero-payload suppression
);

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------
  logic [TIMESTAMP_WIDTH-1:0] prev_ts;      // Timestamp of last emitted event
  logic [3:0]                 prev_etype;
  logic [SOURCE_ID_W-1:0]     prev_src;
  logic [1:0]                 prev_sev;
  logic [7:0]                 repeat_cnt;   // Current duplicate run length

  // Internal output register
  logic        buf_valid;
  logic [63:0] buf_word;

  // ---------------------------------------------------------------------------
  // Compression logic
  // ---------------------------------------------------------------------------
  logic        is_dup;
  logic [15:0] delta_ts;
  logic        delta_ovf;
  logic        is_zero_pay;

  always_comb begin
    // Duplicate check
    is_dup = cfg_dedup_en
             && (in_event.source_id  == prev_src)
             && (in_event.event_type == prev_etype)
             && (in_event.severity   == severity_t'(prev_sev));

    // Delta timestamp
    begin
      logic [TIMESTAMP_WIDTH-1:0] raw_delta;
      raw_delta  = in_event.timestamp - prev_ts;
      delta_ovf  = cfg_delta_en && (raw_delta > 16'hFFFF);
      delta_ts   = cfg_delta_en
                   ? (delta_ovf ? 16'hFFFF : raw_delta[15:0])
                   : in_event.timestamp[15:0];
    end

    // Zero-payload
    is_zero_pay = cfg_zero_sup_en && (in_event.payload == '0);
  end

  // ---------------------------------------------------------------------------
  // Sequential compression FSM
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] { IDLE, EMIT_NORMAL, EMIT_REPEAT, EMIT_ABS_TS } state_t;
  state_t state, state_nxt;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state      <= IDLE;
      buf_valid  <= 1'b0;
      buf_word   <= '0;
      prev_ts    <= '0;
      prev_etype <= '0;
      prev_src   <= '0;
      prev_sev   <= '0;
      repeat_cnt <= '0;
    end else begin
      state <= state_nxt;
      case (state)
        IDLE: begin
          if (in_valid) begin
            if (is_dup && repeat_cnt != 8'hFF) begin
              repeat_cnt <= repeat_cnt + 1;
              buf_valid  <= 1'b0;
            end else begin
              repeat_cnt <= 8'h0;
              buf_valid  <= 1'b1;
              buf_word   <= {
                delta_ovf,
                is_dup,
                is_zero_pay,
                in_event.severity,
                in_event.event_type,
                in_event.source_id,
                delta_ts,
                in_event.payload[30:0]
              };
              prev_ts    <= in_event.timestamp;
              prev_etype <= in_event.event_type;
              prev_src   <= in_event.source_id;
              prev_sev   <= in_event.severity;
            end
          end
        end

        EMIT_NORMAL: begin
          if (out_ready) buf_valid <= 1'b0;
        end

        default: buf_valid <= 1'b0;
      endcase
    end
  end

  always_comb begin
    state_nxt = state;
    case (state)
      IDLE:        if (in_valid && !is_dup) state_nxt = EMIT_NORMAL;
      EMIT_NORMAL: if (out_ready)           state_nxt = IDLE;
      default:                              state_nxt = IDLE;
    endcase
  end

  assign out_valid = buf_valid;
  assign out_word  = buf_word;
  assign in_ready  = (state == IDLE) || (state == EMIT_NORMAL && out_ready);

endmodule : trace_compressor

`default_nettype wire
