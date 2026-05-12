import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// começo do app
void main() {
  runApp(const MeuApp());
}

// configuração geral do app
class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consulta BitCoin',
      debugShowCheckedModeBanner: false,
      home: const TelaPrincipal(),
    );
  }
}

// tela principal
class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  // preço do bitcoin nas 3 moedas
  double precoBRL = 0.0;
  double precoUSD = 0.0;
  double precoEUR = 0.0;

  bool carregando = false;
  String msgErro = '';

  // campo onde o usuário digita o valor
  final TextEditingController campoValor = TextEditingController();

  // moeda de origem e destino dos radio buttons
  String moedaOrigem = 'BRL';
  String moedaDestino = 'USD';

  // resultado da conversão
  double? resultado;

  // busca o preço assim que a tela abre
  @override
  void initState() {
    super.initState();
    buscarPreco();
  }

  // faz a requisição na API e pega o preço atual do bitcoin
  Future<void> buscarPreco() async {
    setState(() {
      carregando = true;
      msgErro = '';
    });

    try {
      final resposta = await http
          .get(Uri.parse('https://blockchain.info/ticker'))
          .timeout(const Duration(seconds: 10));

      if (resposta.statusCode == 200) {
        final dados = jsonDecode(resposta.body);
        setState(() {
          precoBRL = (dados['BRL']['last'] as num).toDouble();
          precoUSD = (dados['USD']['last'] as num).toDouble();
          precoEUR = (dados['EUR']['last'] as num).toDouble();
          carregando = false;
        });
      } else {
        setState(() {
          msgErro = 'Erro ao buscar dados.';
          carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        msgErro = 'Erro de conexão.';
        carregando = false;
      });
    }
  }

  // faz a conversão entre as moedas
  void converter() {
    final valorDigitado = double.tryParse(
      campoValor.text.replaceAll(',', '.'),
    );

    if (valorDigitado == null || valorDigitado <= 0) {
      mostrarAviso('Digite um valor válido.');
      return;
    }

    if (moedaOrigem == moedaDestino) {
      mostrarAviso('Selecione moedas diferentes.');
      return;
    }

    // converte para bitcoin primeiro, depois para a moeda destino
    double emBitcoin = converterParaBTC(valorDigitado, moedaOrigem);
    double valorFinal = converterDeBTC(emBitcoin, moedaDestino);

    setState(() {
      resultado = valorFinal;
    });
  }

  // transforma o valor digitado em bitcoin
  double converterParaBTC(double valor, String moeda) {
    if (moeda == 'BRL') return precoBRL > 0 ? valor / precoBRL : 0;
    if (moeda == 'USD') return precoUSD > 0 ? valor / precoUSD : 0;
    if (moeda == 'EUR') return precoEUR > 0 ? valor / precoEUR : 0;
    return 0;
  }

  // transforma o bitcoin no valor da moeda destino
  double converterDeBTC(double btc, String moeda) {
    if (moeda == 'BRL') return btc * precoBRL;
    if (moeda == 'USD') return btc * precoUSD;
    if (moeda == 'EUR') return btc * precoEUR;
    return 0;
  }

  // limpa o campo e o resultado
  void limparCampos() {
    setState(() {
      campoValor.clear();
      resultado = null;
    });
  }

  void mostrarAviso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  String simboloDaMoeda(String moeda) {
    if (moeda == 'BRL') return 'R\$';
    if (moeda == 'USD') return '\$';
    if (moeda == 'EUR') return '€';
    return '';
  }

  // monta os radio buttons de origem ou destino
  Widget montarRadioButtons({
    required String titulo,
    required String valorSelecionado,
    required ValueChanged<String?> aoMudar,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        RadioListTile<String>(
          title: const Text('R\$'),
          value: 'BRL',
          groupValue: valorSelecionado,
          onChanged: aoMudar,
          dense: true,
        ),
        RadioListTile<String>(
          title: const Text('Dólar'),
          value: 'USD',
          groupValue: valorSelecionado,
          onChanged: aoMudar,
          dense: true,
        ),
        RadioListTile<String>(
          title: const Text('Euro'),
          value: 'EUR',
          groupValue: valorSelecionado,
          onChanged: aoMudar,
          dense: true,
        ),
      ],
    );
  }

  // fazendo a tela
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App consulta preço BitCoin'),
        backgroundColor: const Color(0xFFF7931A),
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // preços atuais do bitcoin
            if (carregando)
              const Center(child: CircularProgressIndicator())
            else if (msgErro.isNotEmpty)
              Text(msgErro, style: const TextStyle(color: Colors.red))
            else ...[
              Text('Valor BitCoin R\$: R\$ ${precoBRL.toStringAsFixed(2)}'),
              Text('Valor BitCoin \$: \$ ${precoUSD.toStringAsFixed(2)}'),
              Text('Valor BitCoin €: € ${precoEUR.toStringAsFixed(2)}'),
            ],

            const Divider(height: 32),

            // campo de texto para digitar o valor
            const Text('Digite o valor a ser convertido'),
            const SizedBox(height: 8),
            TextField(
              controller: campoValor,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Valor',
              ),
            ),

            const SizedBox(height: 12),

            // radio buttons lado a lado
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: montarRadioButtons(
                    titulo: 'Origem',
                    valorSelecionado: moedaOrigem,
                    aoMudar: (val) =>
                        setState(() => moedaOrigem = val ?? moedaOrigem),
                  ),
                ),
                Expanded(
                  child: montarRadioButtons(
                    titulo: 'Destino',
                    valorSelecionado: moedaDestino,
                    aoMudar: (val) =>
                        setState(() => moedaDestino = val ?? moedaDestino),
                  ),
                ),
              ],
            ), 

            // resultado da conversão
            if (resultado != null) ...[
              Text('Valor a ser convertido: ${simboloDaMoeda(moedaOrigem)} ${campoValor.text}'),
              Text('Valor convertido: ${simboloDaMoeda(moedaDestino)} ${resultado!.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
            ],

            // botões verificar, calcular e limpar
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: buscarPreco,
                    child: const Text('Verificar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: converter,
                    child: const Text('Calcular'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: limparCampos,
                    child: const Text('Limpar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}