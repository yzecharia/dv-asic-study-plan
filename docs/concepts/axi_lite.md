# AXI-Lite

**Category**: Protocols · **Used in**: W11 (slave), W14 (RAL adapter), W20 (capstone) · **Type**: authored

The simplest AMBA AXI flavour: 32-bit addresses and data, no bursts,
no IDs. Five independent channels: AW (write address), W (write
data), B (write response), AR (read address), R (read data). Each
channel uses the `valid`/`ready` handshake.

## Channels

| Channel | Direction | Carries |
|---|---|---|
| AW (write address) | M → S | `awaddr`, `awprot`, `awvalid`, `awready` |
| W  (write data)    | M → S | `wdata`, `wstrb`, `wvalid`, `wready` |
| B  (write resp)    | S → M | `bresp`, `bvalid`, `bready` |
| AR (read address)  | M → S | `araddr`, `arprot`, `arvalid`, `arready` |
| R  (read data)     | S → M | `rdata`, `rresp`, `rvalid`, `rready` |

Channel independence is real: AW and W can complete out of order
relative to each other, and a master may issue many AR before an R
returns. The slave **must** respond on B exactly once per AW+W pair
and on R exactly once per AR.

## Slave FSM (W11 design HW)

```systemverilog
typedef enum logic [1:0] {
    S_IDLE,
    S_WRITE_DATA,    // saw AW, waiting for W
    S_WRITE_RESP     // ready to send B
} wstate_t;
```

Common gotchas:

- `awready` may be 1 in `S_IDLE` to accept new addresses; the slave
  must register `awaddr` once accepted.
- `wstrb` is a per-byte enable. In a 32-bit slave, `wstrb=4'hF` means
  full word; `4'h3` means lower halfword only. Junior bug:
  ignoring `wstrb` and writing the whole word always.

## SVA bundle

```systemverilog
// AWREADY may go high before AWVALID (slave eager-accept)
// AWVALID must hold until AWREADY (master sticky)
property p_awvalid_sticky;
    @(posedge aclk) disable iff (!aresetn)
        (awvalid && !awready) |=> awvalid;
endproperty
assert property (p_awvalid_sticky);

// Exactly one B per AW+W
// (cover property — counts AW handshakes vs B handshakes)
```

## RAL integration (W14, W20)

The RAL `uvm_reg_adapter::reg2bus` translates a `uvm_reg_bus_op` to
an AXI-Lite transaction sequence. The hand-written adapter you build
in W14 takes a `uvm_reg_bus_op` (kind=READ/WRITE, addr, data, byte_en)
and emits the right channel handshakes via the AXI-Lite UVC driver.

```systemverilog
class axi_lite_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils(axi_lite_reg_adapter)
    function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        axi_lite_seq_item item = axi_lite_seq_item::type_id::create("axi_lite_seq_item");
        item.kind = (rw.kind == UVM_WRITE) ? AXI_WRITE : AXI_READ;
        item.addr = rw.addr;
        if (rw.kind == UVM_WRITE) begin
            item.data = rw.data;
            item.strb = rw.byte_en;
        end
        return item;
    endfunction
    function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        axi_lite_seq_item item;
        $cast(item, bus_item);
        rw.kind   = (item.kind == AXI_WRITE) ? UVM_WRITE : UVM_READ;
        rw.addr   = item.addr;
        rw.data   = item.data;
        rw.status = (item.resp == AXI_OKAY) ? UVM_IS_OK : UVM_NOT_OK;
    endfunction
endclass : axi_lite_reg_adapter
```

## Reading

- ARM *AMBA AXI and ACE Protocol Specification* (IHI0022E),
  ch.A1–A5 + ch.B (AXI-Lite specifics) — free PDF from arm.com.
- UVM Cookbook RAL section — adapter patterns.

## Cross-links

- `[[ready_valid_handshake]]` — the per-channel primitive.
- `[[uvm_ral]]` — the abstraction layer the adapter feeds.
