import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  LatLng? _ubicacionActual; // Permite que sea nulo al inicio
  bool _cargandoUbicacion = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionActual();
  }

  void _obtenerUbicacionActual() async {
    // Verifica si el servicio de ubicación está habilitado
    bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      setState(() {
        _errorMessage = 'El servicio de ubicación está deshabilitado.';
        _cargandoUbicacion = false;
      });
      return;
    }

    // Verifica los permisos de ubicación
    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        setState(() {
          _errorMessage = 'Los permisos de ubicación están denegados.';
          _cargandoUbicacion = false;
        });
        return;
      }
    }

    // Escuchar cambios en la ubicación
    Geolocator.getPositionStream(locationSettings: LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)).listen((Position position) {
      setState(() {
        _ubicacionActual = LatLng(position.latitude, position.longitude);
        _cargandoUbicacion = false;
        _errorMessage = null; // Resetear error si hay nueva ubicación
      });
      print('Ubicación actual: ${position.latitude}, ${position.longitude}');
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa de Ubicación'),
      ),
      body: _cargandoUbicacion
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: _ubicacionActual == null
                ? Center(child: Text('No se pudo obtener la ubicación: $_errorMessage'))
                : FlutterMap(
              options: MapOptions(
                initialCenter: _ubicacionActual!,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _ubicacionActual!,
                      width: 80.0,
                      height: 80.0,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 50.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_ubicacionActual != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Ubicación actual: ${_ubicacionActual!.latitude}, ${_ubicacionActual!.longitude}',
                style: TextStyle(fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }
}
