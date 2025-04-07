import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guess_the_flag/country_codes.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Guess The Flag!",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});


  @override
  State<MyHomePage> createState() => _MyHomePageState();
}



enum MapState {
  ON,
  WRONG_ANSWER,
  OFF
}

extension on MapState {
  MapState operator+(final int i) {
    return MapState.values[(index + i) % MapState.values.length];
  }
}


class _MyHomePageState extends State<MyHomePage> {
  final random = Random();

  late Country country;
  List<Country> options = List<Country>.filled(4, ("", "", "", 0, .0, .0));
  int key = 0;
  MapState map_state = MapState.WRONG_ANSWER;

  double turns = 0;

  bool prevent_touch = false;

  List<Country> country_list = [...COUNTRIES]; // make a copy

  int score = 0;
  // int? high;
  final prefs = SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: { /*"high",*/ "map_state"}
    ),
  );


  Future<void> initPrefs() async {
    final SharedPreferencesWithCache preferences = await prefs;
    // if(!preferences.containsKey("high")) preferences.setInt("high", 0);
    if(!preferences.containsKey("map_state")) preferences.setInt("map_state", map_state.index);

    setState(() {
      // high = preferences.getInt("high");
      map_state = MapState.values[preferences.getInt("map_state") ?? map_state.index];
    });
  }


  @override
  void initState() {
    super.initState();
    initPrefs();

    country_list.shuffle();
    country = country_list[0]; // start with the first one in the shuffled list
    // country = country_list[random.nextInt(country_list.length)];
    generateAnswers();

  }

  final ConfettiController confetti = ConfettiController(duration: const Duration(seconds: 6));

  @override
  void dispose() {
    confetti.dispose();
    super.dispose();
  }


  bool winning = false;
  Future<void> win() async {
    setState(() => winning = true);
    confetti.play();
    await Future.delayed(confetti.duration + const Duration(seconds: 4)); // wait for confetti to finish
    confetti.stop();
    setState(() => winning = false);
  }


  // generates answers for current chosen country
  void generateAnswers(){
    options[0] = country;
    for(int i = 1; i < options.length; ++i){ // Possibly add more options in the future?

      Country new_option;
      // ensuring not to show the same answer again
      do new_option = COUNTRIES[random.nextInt(COUNTRIES.length)]; while(options.contains(new_option));

      options[i] = new_option;
    }

    options.shuffle(); // so that the correct answer is not always at the same position
  }

  int index = 0;
  void updateFlag() {
    // Country new_code = COUNTRIES[random.nextInt(COUNTRIES.length)];
    // while (new_code == country) // ensuring not to show the same flag again
    //   new_code = COUNTRIES[random.nextInt(COUNTRIES.length)];

    country = country_list[index];
    generateAnswers();
    key = 1 - key;
    // setState(() => key = 1 - key); // switching key to force the AnimatedSwitcher to rebuild
  }


  void reset() {
    country_list.shuffle();
    score = 0;
    turns = 1 - turns; // which way the score turns when reseting
    index = 0;
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Scaffold(
          // backgroundColor: const Color(0x614A88FF),
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: const BoxDecoration(image: DecorationImage(
              image: AssetImage("assets/bg/BG.png"),
              fit: BoxFit.cover
            )),
            child: Center(
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Stack(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 32),
                              child: IconButton(
                                icon: Icon(
                                  map_state == MapState.ON ? Icons.public_outlined :
                                  map_state == MapState.WRONG_ANSWER ? Icons.error_outline_outlined :
                                  Icons.cancel_outlined,
                                  color: const Color(0xADB6C4FF),
                                ),
                                iconSize: 46,
                                onPressed: () async {
                                  setState(() => ++map_state );

                                  final SharedPreferencesWithCache preferences = await prefs;
                                  preferences.setInt("map_state", map_state.index);
                                },
                              ),
                            ),
                          ),

                          Align(
                            alignment: Alignment.center,
                            child: AnimatedRotation(
                              duration: const Duration(milliseconds: 500),
                              turns: turns,
                              curve: Curves.fastEaseInToSlowEaseOut,
                              child: Text(
                                "$score/${country_list.length}",
                                style: const TextStyle(fontSize: 38, color: Color(0xADB6C4FF)),
                              ),
                            ),
                          )
                        ],
                      ),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Container(
                          key: ValueKey(key),
                          decoration: const BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 24,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: CountryFlag.fromCountryCode(
                            country.$2, // Country code
                            width: size.width / 2.4 * 1.8,
                            height:size.width / 2.4 * 1.35,
                            shape: const RoundedRectangle(24),
                          ),
                        ),
                      ),

                      const SizedBox(height: 0),

                      OptionsWidget(
                        options: options,
                        correct: options.indexOf(country),
                        preventTouch: () => setState(() => prevent_touch = true),
                        almost_won: score >= country_list.length -1, // will never be greater but better safe than sorry
                        onWin: () async {
                          await win();
                          reset();
                        },

                        onCorrect: () => setState(() => (score++, ++index)),

                        onWrong: () => setState( reset ),

                        callback: () {
                          setState( () {
                            prevent_touch = false;
                            updateFlag();
                          });
                          // updateFlag();
                        },
                        map_state: map_state,
                      ),
                    ],
                  ),



                  if(prevent_touch) Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.transparent,
                  )
                ],
              ),
            ),
          ),
        ),

        // if(winning)
        AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: winning ? 1.0 : 0.0,
          child: Align(
            alignment: Alignment.center,
            child: Text("You Won!",
              style: TextStyle(
                fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                color: Colors.blue.shade200,
                decoration: TextDecoration.none,
                fontSize: 64,
              ),
            ),
          ),
        ),

        ConfettiWidget(
          confettiController: confetti,
          blastDirection: pi / 2,
          emissionFrequency: .35,
          blastDirectionality: BlastDirectionality.explosive,
        ),
      ],
    );
  }
}




class OptionsWidget extends StatefulWidget {
  const OptionsWidget({
    super.key,
    required this.options,
    required this.correct,
    required this.map_state,
    required this.preventTouch,
    required this.almost_won,
    required this.onWin,
    required this.onCorrect,
    required this.onWrong,
    required this.callback,
  });

  final List<Country> options;
  final int correct;
  final MapState map_state;
  final void Function() preventTouch;
  final bool almost_won;
  final Future<void> Function() onWin;
  final void Function() onCorrect;
  final void Function() onWrong;
  final void Function() callback;

  @override
  State<OptionsWidget> createState() => _OptionsWidgetState();
}

class _OptionsWidgetState extends State<OptionsWidget> {
  // static const BUTTON_COLOR = Color(0xADB6C4FF);
  static const BUTTON_COLOR = Colors.white70;

  late List<Color> colors = List.filled(widget.options.length, BUTTON_COLOR);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Column(
      children: [
        for(int i = 0; i < widget.options.length; ++i)
          Padding(
            // padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            padding: const EdgeInsets.only(right: 24, left: 24, bottom: 6),
            child: TextButton(
              style: OutlinedButton.styleFrom(backgroundColor: colors[i]),
              child: SizedBox(
                width: size.width * .7,
                child: Text(
                  widget.options[i].$1, //* Country name
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, color: Colors.black),
                ),
              ),
              onPressed: () async {
                setState(() {
                  colors[i] = Colors.red;
                  colors[widget.correct] = Colors.green;
                });

                widget.preventTouch();
                await Future.delayed(const Duration(milliseconds: 1250));

                i == widget.correct? widget.onCorrect() : widget.onWrong();

                final bool did_win = widget.almost_won && i == widget.correct;
                if(did_win) await widget.onWin();


                colors[i] = colors[widget.correct] = BUTTON_COLOR;

                switch(widget.map_state){
                  case MapState.WRONG_ANSWER when i != widget.correct:
                  case MapState.ON:
                    if(context.mounted) await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Globe(point: Point(
                          id: "1",
                          label: widget.options[widget.correct].$1,
                          isLabelVisible: true,
                          coordinates: GlobeCoordinates(widget.options[widget.correct].$5, widget.options[widget.correct].$6),
                          style: const PointStyle(size: 6, color: Colors.white),
                        )),
                      )
                    );
                    await Future.delayed(const Duration(milliseconds: 500)); // slight delay after closing the map
                  default:
                }

                widget.callback();
              },
            ),
          )
      ],
    );
  }
}



class Globe extends StatelessWidget {
  const Globe({super.key, required this.point});
  final Point point;

  @override
  Widget build(BuildContext context) {
    final controller = FlutterEarthGlobeController(
      rotationSpeed: .05,
      isBackgroundFollowingSphereRotation: true,
      surface: Image.asset("assets/2k_earth_day.jpg").image,
      background: Image.asset("assets/2k_stars.jpg").image,
    );
    
    controller.addPoint(point);

    return Scaffold(
      body: Stack(
        children: [
          FlutterEarthGlobe(
            radius: 140,
            controller: controller,
          ),
          const Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(top: 48, left: 12),
              child: BackButton(
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
    );
  }
}


