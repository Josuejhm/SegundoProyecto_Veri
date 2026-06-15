///////////////////////////////////////////////////////////////////////////////
// Archivo:     apb_rand_seq.sv
// Descripción: Secuencia APB aleatoria — genera N transacciones APB totalmente
//              aleatorias usando los constraints definidos en apb_seq_item.
//
//              Por defecto restringe accesos a direcciones mapeadas.
//              Para ejercer direcciones no mapeadas, la vseq debe habilitar
//              addr_unmapped_c antes de llamar start().
///////////////////////////////////////////////////////////////////////////////

class apb_rand_seq extends apb_base_seq;
  `uvm_object_utils(apb_rand_seq)

  // Número de transacciones a generar
  int unsigned n_txns        = 20;

  // Si 1, fuerza solo accesos a direcciones no mapeadas
  bit          unmapped_only = 1'b0;

  function new(string name = "apb_rand_seq");
    super.new(name);
  endfunction

  task body();
    apb_seq_item item;

    repeat (n_txns) begin
      item = apb_seq_item::type_id::create("apb_rand_item");
      start_item(item);

      if (unmapped_only) begin
        item.addr_mapped_c.constraint_mode(0);
        item.addr_unmapped_c.constraint_mode(1);
      end

      if (!item.randomize())
        `uvm_fatal("APB_RAND_SEQ", "randomize() failed")

      finish_item(item);
    end
  endtask

endclass : apb_rand_seq