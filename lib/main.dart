import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';

void main() {
  runApp(const MapCep());
}

class MapCep extends StatelessWidget {
  const MapCep({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: "CEP no flutter Map", home: const TelaMapa());
  }
}

class TelaMapa extends StatefulWidget {
  const TelaMapa({super.key});

  @override
  State<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends State<TelaMapa> {
  final TextEditingController _cepController = TextEditingController();
  latlong.LatLng _centroAtual = const latlong.LatLng(-15.7942, -47.8825);
  double _zoomAtual = 4.0;
  final MapController _mapController = MapController();

  // Função para buscar o CEP

  Future<void> _buscaCep() async {
    final String cepInput = _cepController.text;
    final String cep = cepInput.replaceAll(RegExp('[^0-9]'), '');
    if (cep.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "CEP inválido. Deve conter 8 dígitos. CEP informado: $cep",
          ),
        ),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cep/json/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['erro'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("CEP não encontrado: $cepInput")),
          );
          return;
        }

        final String endereco =
            "${data['logradouro']}, ${data['bairro']}, ${data['localidade']}, ${data['uf']}";
        print("Endereço encontrado: $endereco");

        List<Location> locais = await locationFromAddress(endereco);
        if (locais.isNotEmpty) {
          final Location primeiroLugar = locais.first;
          final latlong.LatLng novaPosicao = latlong.LatLng(
            primeiroLugar.latitude,
            primeiroLugar.longitude,
          );

          setState(() {
            _centroAtual = novaPosicao; // Atualiza a coordenada central
            _zoomAtual = 16.0;
          });

          // Move o mapa para a nova posição central
          _mapController.move(_centroAtual, _zoomAtual);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Não foi possível encontrar coordenadas para o endereço: $endereco",
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao buscar CEP: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("Erro na busca de CEP: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ocorreu um erro ao processar a solicitação.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    MapController mapController;
    return Scaffold(
      appBar: AppBar(
        title: Text("Buscar o CEP com flutter Map"),
        backgroundColor: Colors.teal.shade200,
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(14.0),
            child: TextField(
              controller: _cepController,
              decoration: InputDecoration(
                labelText: "Insira o CEP",
                hintText: "Ex: 59550000",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: _buscaCep,
                  icon: Icon(Icons.search),
                ),
              ),
              keyboardType: TextInputType.number,
              maxLength: 8,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                Colors.blueAccent,
              ),
              foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
              shadowColor: MaterialStateProperty.all<Color>(Colors.black),
              padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              ),
            ),
            onPressed: (){_buscaCep();},
            child: Text("Buscar CEP"),
          ),

          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _centroAtual,
                    initialZoom: _zoomAtual,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.map_cep',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _centroAtual, // Deve ser um LatLng
                          width: 80,
                          height: 80,
                          child: Icon(
                            Icons.location_on_sharp,
                            size: 50,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
