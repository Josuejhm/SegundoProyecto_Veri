///////////////////////////////////////////////////////////////////////////////
// File:        md_rx_rand_seq.sv
// Description: Secuencia MD RX con mezcla aleatoria de transfers legales
//              e ilegales. El campo illegal_weight controla el porcentaje
//              de transfers ilegales (0=todos legales, 100=todos ilegales).
///////////////////////////////////////////////////////////////////////////////

class md_rx_rand_seq extends md_rx_base_seq;
  `uvm_object_utils(md_rx_rand_seq)

  int unsigned n_transfers    = 50;
  int unsigned illegal_weight = 20; // porcentaje de transfers ilegales (0-100)

  function new(string name = "md_rx_rand_seq");
    super.new(name);
  endfunction

  task body();
    md_rx_seq_item item;
    int unsigned rnd;
    repeat (n_transfers) begin
      item = md_rx_seq_item::type_id::create("md_rx_rand_item");
      start_item(item);

      // Decidir si este transfer es ilegal según el peso
      rnd = $urandom_range(0, 99);
      if (rnd < illegal_weight) begin
        item.legal_c.constraint_mode(0);
        item.illegal_c.constraint_mode(1);
      end else begin
        item.legal_c.constraint_mode(1);
        item.illegal_c.constraint_mode(0);
      end

      if (!item.randomize())
        `uvm_fatal("MD_RX_RAND_SEQ", "randomize() failed")
      finish_item(item);
    end
  endtask

endclass : md_rx_rand_seq
