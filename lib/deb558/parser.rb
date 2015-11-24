module Deb558
  class Parser

    def parse_file(filename)
      records = []
      read_file filename do | block |
        records << parse_record(block)
      end
      records
    end

    private

    def read_file(filename)
      remove_linebreaks(filename)
      File.open(filename) do |file|
        until file.eof?
          block = file.read Config::BLOCK_SIZE
          yield block
        end
      end
    end

    def parse_record(block)
      case record_id block
        when Config::HEADER_RECORD_ID
          parse_header_record block
        when Config::DETAIL_RECORD_ID
          parse_detail_record block
        when Config::TRAILER_RECORD_ID
          parse_trailer_record block
        else
          raise 'Invalid Record'
      end
    end

    def parse_detail_record(block)
      case record_type block
        when Config::PREVIOUS_BALANCE_RECORD_TYPE
          parse_previous_balance_record block
        when Config::JOURNAL_ENTRY_RECORD_TYPE
          parse_journal_entry_record block
        when Config::CURRENT_BALANCE_RECORD_TYPE
          parse_current_balance_record block
        else
          raise 'Invalid Detail Record'
      end
    end

    def parse_header_record(block)
      {
          identificacao_registro_header:  block[0].to_i,
          codigo_identificador_servico: block[9..10].to_i,
          tipo_servico: block[11..25],
          codigo_convenio: block[37..45],
          codigo_compe_BB: block[76..78].to_i,
          banco_brasil: block[79..93],
          densidade_gravacao: block[100..104].to_i,
          unidade_medida: block[105..107],
          cnpj_disponibilizado_extrato: block[109..122],
          data_gravacao: parse_date(block[181..188]),
          codigo_servico: block[189..190].to_i,
          codigo_compe_BB2: block[191..193].to_i,
          sequencial_registro: block[194..199].to_i
      }
    end

    def parse_previous_balance_record(block)
      {
          codigo_registro: block[0].to_i,
          tipo_inscricao: block[1..2].to_i,
          numero_inscricao: block[3..16],
          prefixo_agencia: block[17..20],
          numero_conta_cliente: strip_left_zeros(block[29..39]),
          digito_verificador_conta_cliente: block[40],
          tipo_registro: block[41].to_i,
          valor_bloqueado_tempo_indeterminado: parse_money(block[42..58]),
          codigo_convenio: block[59..67],
          numero_ordem_extrato_magnetico: block[68..70].to_i,
          saldo_anterior: parse_money(block[86..103]),
          status_conta: block[104],
          total_valores_bloqueados_4_a_9_dias: parse_money(block[105..121]),
          valor_bloqueado_por_3_dias: parse_money(block[122..138]),
          valor_bloqueado_por_2_dias: parse_money(block[139..155]),
          valor_bloqueado_por_1_dia: parse_money(block[156..172]),
          data_saldo_anterior: parse_date(block[181..188]),
          tipo_servico: block[189..190].to_i,
          codigo_compe_BB: block[191..193],
          sequencial_registro: block[194..199].to_i
      }
    end

    def parse_journal_entry_record(block)
      {
          codigo_registro: block[0].to_i,
          tipo_inscricao: block[1..2].to_i,
          numero_inscricao_cliente: block[3..16],
          prefixo_agencia: block[17..20],
          numero_conta_cliente: strip_left_zeros(block[29..39]),
          digito_verificador_conta_cliente: block[40],
          tipo_registro: block[41].to_i,
          categoria_lancamento: block[42..44],
          codigo_numerico_lancamento: block[45..48].to_i,
          literal_codigo_numerico: block[49..73].strip,
          numero_documento_lancado: block[74..79],
          valor_lancamento: parse_money(block[86..103]),
          numero_lote: block[110..114].to_i,
          prefixo_agencia_origem_lancamento: block[115..118].to_i,
          codigo_compe_banco_origem: block[119..121],
          identificador_cpmf: block[122],
          codigo_sub_historico: block[128..134].to_i,
          numero_documento: block[135..149].to_i,
          data_balancete: parse_date(block[173..180]),
          data_lancamento: parse_date(block[181..188]),
          tipo_servico: block[189..190].to_i,
          codigo_compe_bb: block[191..193],
          sequencial_registro: block[194..199].to_i
      }
    end

    def parse_current_balance_record(block)
      {
          codigo_registro: block[0].to_i,
          tipo_inscricao: block[1..2].to_i,
          numero_inscricao: block[3..16],
          prefixo_agencia: block[17..20],
          numero_conta_cliente: strip_left_zeros(block[29..39]),
          digito_verificador_conta_cliente: block[40],
          tipo_registro: block[41].to_i,
          saldo_liquido_fundo_curto_prazo: parse_money(block[42..58]),
          valor_cpmf: parse_money(block[59..75]),
          saldo_atual: parse_money(block[86..103]),
          status_saldo_atual: block[104],
          estagio_saldo_atual: block[105],
          saldo_liquido_fundo_commodities: parse_money(block[106..122]),
          juros_capitalizados: parse_money(block[123..137]),
          iof_capitalizados: parse_money(block[138..152]),
          limite_cheque_ouro_sem_centavos: block[153..161].to_f,
          saldo_liquido_fundo_curto_prazo2: parse_money(block[162..178]),
          data_saldo_atual: parse_date(block[181..188]),
          codigo_servico: block[189..190],
          codigo_compe_bb: block[191..193],
          sequencial_registro: block[194..199].to_i
      }
    end


    def parse_trailer_record(block)
      {
          identificacao_trailer: block[0].to_i,
          total_contas_que_tiveram_extratos: block[1..5].to_i,
          somatorio_registros_tipo_1: block[6..11].to_i,
          total_valores_lançados_a_debito: parse_money(block[12..27]),
          total_valores_lançados_a_credito: parse_money(block[28..43]),
          codigo_serviço: block[189..190],
          codigo_compe_bb: block[191..193],
          sequencial_registro: block[194..199].to_i
      }
    end

    def record_type(block)
      block[Config::RECORD_TYPE_POSITION].to_i
    end

    def record_id(block)
      block[Config::RECORD_ID_POSITION].to_i
    end

    def parse_money(string)
      strip_left_zeros(string).to_f / 100
    end

    def parse_date(string)
        Date.strptime(string, '%d%m%Y') rescue nil
    end

    def strip_left_zeros(string)
      string.sub(/^[0]+/,'')
    end

    def remove_linebreaks(filename)
      File.write(filename, File.read(filename).gsub(/(\n|\r)/, ''))
    end
  end
end
