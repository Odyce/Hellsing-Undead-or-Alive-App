import 'package:flutter/material.dart';
import 'package:page_flip/page_flip.dart';
import 'package:hellsing_undead_or_applive/pages/models.dart';

class VictorianBook extends StatefulWidget {
  const VictorianBook({super.key});

  @override
  State<VictorianBook> createState() => _VictorianBookState();
}

class _VictorianBookState extends State<VictorianBook> {
  final _controller = GlobalKey<PageFlipWidgetState>();

  void _goTo(int pageIndex) {
    _controller.currentState?.goToPage(pageIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageFlipWidget(
        key: _controller,
        backgroundColor: Colors.black, // optionnel, pour mieux “cadrer” le livre
        lastPage: const SizedBox.shrink(), // ou ta 4e de couverture
        children: <Widget>[
          // 0: Couverture
          //VictorianCoverPage(onGoToPage: _goTo),
          // 1: Sommaire
          VictorianTocPage(onGoToPage: _goTo),

          // ... 2..46 tes pages ...
          // 47: 4e de couverture
        ],
      ),
    );
  }
}
