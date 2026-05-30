import 'package:flutter/material.dart';

class PlotColormap {
  final String name;
  final List<Color> colors;

  const PlotColormap({required this.name, required this.colors});

  static const List<PlotColormap> all = [
    PlotColormap(name: 'Greys', colors: [
      Color(0xFFECECEC), Color(0xFFCACACA), Color(0xFF999999), 
      Color(0xFF6A6A6A), Color(0xFF353535), Color(0xFF000000),
    ]),
    PlotColormap(name: 'Greens', colors: [
      Color(0xFFDFF3DA), Color(0xFFB2E0AC), Color(0xFF78C679), 
      Color(0xFF39A257), Color(0xFF0C7735), Color(0xFF00441B),
    ]),
    PlotColormap(name: 'Oranges', colors: [
      Color(0xFFFEE2C6), Color(0xFFFDBE84), Color(0xFFFD9040), 
      Color(0xFFEB600E), Color(0xFFB83C02), Color(0xFF7F2704),
    ]),
    PlotColormap(name: 'BuGn', colors: [
      Color(0xFFE0F3F5), Color(0xFFB0E1D6), Color(0xFF6AC4A7), 
      Color(0xFF39A569), Color(0xFF0C7735), Color(0xFF00441B),
    ]),
    PlotColormap(name: 'GnBu', colors: [
      Color(0xFFDCF1D7), Color(0xFFB9E3BC), Color(0xFF7FCDC3), 
      Color(0xFF45A8CD), Color(0xFF1475B2), Color(0xFF084081),
    ]),
    PlotColormap(name: 'PuBu', colors: [
      Color(0xFFE7E3F0), Color(0xFFB9C6E0), Color(0xFF78ABD0), 
      Color(0xFF2987BC), Color(0xFF046299), Color(0xFF023858),
    ]),
    PlotColormap(name: 'RdPu', colors: [
      Color(0xFFFDDBD7), Color(0xFFFBB0BA), Color(0xFFF76CA3), 
      Color(0xFFD02690), Color(0xFF8C0179), Color(0xFF49006A),
    ]),
    PlotColormap(name: 'PuBuGn', colors: [
      Color(0xFFE7DFEE), Color(0xFFB9C6E0), Color(0xFF6CABD0), 
      Color(0xFF288CB1), Color(0xFF01736A), Color(0xFF014636),
    ]),
    PlotColormap(name: 'YlOrBr', colors: [
      Color(0xFFFFF3B4), Color(0xFFFED26D), Color(0xFFFE9C2C), 
      Color(0xFFE3660F), Color(0xFFAB3C03), Color(0xFF662506),
    ]),
    PlotColormap(name: 'Reds', colors: [
      Color(0xFFFED9C9), Color(0xFFFCA588), Color(0xFFFB6D4D), 
      Color(0xFFE53228), Color(0xFFB21218), Color(0xFF67000D),
    ]),
    PlotColormap(name: 'Blues', colors: [
      Color(0xFFD9E8F5), Color(0xFFB0D2E7), Color(0xFF6FB0D7), 
      Color(0xFF3989C1), Color(0xFF115CA5), Color(0xFF08306B),
    ]),
    PlotColormap(name: 'Purples', colors: [
      Color(0xFFEBE9F3), Color(0xFFCACAE3), Color(0xFFA09DCA), 
      Color(0xFF7A71B4), Color(0xFF5C3696), Color(0xFF3F007D),
    ]),
    PlotColormap(name: 'BuPu', colors: [
      Color(0xFFDAE7F1), Color(0xFFADC7E0), Color(0xFF8D99C8), 
      Color(0xFF8B60AC), Color(0xFF832088), Color(0xFF4D004B),
    ]),
    PlotColormap(name: 'OrRd', colors: [
      Color(0xFFFEE4C0), Color(0xFFFDC690), Color(0xFFFC915C), 
      Color(0xFFE9573D), Color(0xFFC0110B), Color(0xFF7F0000),
    ]),
    PlotColormap(name: 'PuRd', colors: [
      Color(0xFFE3D9EB), Color(0xFFCEA5D0), Color(0xFFDD69B2), 
      Color(0xFFE0237C), Color(0xFFAB064A), Color(0xFF67001F),
    ]),
    PlotColormap(name: 'YlGn', colors: [
      Color(0xFFF1FAB5), Color(0xFFC1E698), Color(0xFF7CC87B), 
      Color(0xFF39A056), Color(0xFF0C723B), Color(0xFF004529),
    ]),
    PlotColormap(name: 'YlGnBu', colors: [
      Color(0xFFE6F5B2), Color(0xFFA0DAB8), Color(0xFF46B8C3), 
      Color(0xFF1E83BA), Color(0xFF24439B), Color(0xFF081D58),
    ]),
    PlotColormap(name: 'YlOrRd', colors: [
      Color(0xFFFFE998), Color(0xFFFEC45F), Color(0xFFFD903D), 
      Color(0xFFF54026), Color(0xFFCA0923), Color(0xFF800026),
    ]),
  ];
}
