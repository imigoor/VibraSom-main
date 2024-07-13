import 'package:flutter/material.dart';
import 'package:VibraSound/core/app_export.dart';
import 'package:http/http.dart' as http;
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

class AppState with ChangeNotifier {
  List<double> amplitudes = [];
  String bpm = "";
  List<int> vibrationAmplitudes = [];
  double amplitude_segmento = 0.0;
  int vibrationDuration = 0;

  void updateValues(List<double> newAmplitudes, String newBpm,
      List<int> newVibrationAmplitudes, int newVibrationDuration) {
    amplitudes = newAmplitudes;
    bpm = newBpm;
    vibrationAmplitudes = newVibrationAmplitudes;
    vibrationDuration = newVibrationDuration; // Convertendo para inteiro
    notifyListeners();
  }

  void updateAmplitude(double amplitude) {
    amplitude_segmento = amplitude;
    print('Amplitude atualizada: $amplitude_segmento');
    notifyListeners();
  }

  void updateVibrationDuration(double duration) {
    vibrationDuration = duration.toInt(); // Convertendo para inteiro
    notifyListeners();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late String selectedFileName;
  late AudioPlayer _audioPlayer;
  bool isLightOn = true;
  bool isVibrationOn = true;



  @override
  void initState() {
    super.initState();
    selectedFileName = "-";
    _audioPlayer = AudioPlayer();
    
  }

  void showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Informações da música carregadas com sucesso'),
      ),
    );
  }

  Future<void> uploadAudio(String filePath) async {
    try {
      final url = Uri.parse('http://10.0.149.67:5000/');
      var request = http.MultipartRequest('POST', url)
        ..files.add(await http.MultipartFile.fromPath('file', filePath));

      var response = await request.send();

      if (response.statusCode == 200) {
        final Map<String, dynamic> result =
            json.decode(await response.stream.bytesToString());

        if (result.containsKey('error')) {
          // Tratar erro no servidor
          print('Erro no servidor: ${result['error']}');
        } else {
          // Processar a resposta do servidor
          final String bpm = result['bpm'].toString();
          final List<double> amplitudes = List.castFrom(result['amplitudes']);
          final List<int> vibrationAmplitudes =
              List.castFrom(result['vibration_amplitudes']);
          final vibrationDuration = result['interval_duration'];
          // Atualizar o estado global do app para deixar as informações do servidor visíveis para todos os widgets
          Provider.of<AppState>(context, listen: false).updateValues(
            amplitudes,
            bpm,
            vibrationAmplitudes,
            vibrationDuration,
          );
          print('BPM: $bpm');
          print('Amplitudes: $amplitudes');
          print('Vibration Amplitudes: $vibrationAmplitudes');
          print('Vibration Duration: $vibrationDuration');

          showSuccessSnackbar();
        }
      } else {
        print('Falha na requisição: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Erro ao fazer upload: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color.fromARGB(255, 255, 255, 255),
          ),
          Positioned(
            top: 30,
            child: Image(
              image: AssetImage('images/lara.png'),
              height: 150,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 160,
            child: Text(
              'VibraSound',
              style: TextStyle(
                color: Colors.green.shade900,
                fontSize: 50.0,
                fontFamily: 'Asul',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Positioned(
            top: 240,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomToggleButton(
                  icon: Icons.vibration,
                  onChanged: (value) async {
                    setState(() {
      isVibrationOn = value;
    });
                    //final hasVibrator = await Vibration.hasVibrator();
                    //final hasCustomVibrationsSupport =
                        //await Vibration.hasCustomVibrationsSupport();
                    //final hasAmplitudeControl =
                        //await Vibration.hasAmplitudeControl();
                    //if (hasVibrator != null && hasVibrator) {
                      //Vibration.vibrate(amplitude: 128, duration: 1000);
                      //if (hasCustomVibrationsSupport != null &&
                          //hasCustomVibrationsSupport) {
                        //print("Dispositivo suporta vibrações personalizadas");
                      //if (hasAmplitudeControl != null &&
                          //hasAmplitudeControl) {
                          //print("Dispositivo suporta controle de amplitude");}}}

                    
                  },
                ),
                SizedBox(width: 60),
                CustomToggleButton(
                  icon: Icons.lightbulb,
                  onChanged: (value) {
                    setState(() {
                      isLightOn = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.75,
            child: SongNameWidget(fileName: selectedFileName),
          ),
          CustomSlider(
            audioPlayer: _audioPlayer,
        
            
            
          ),
          Positioned(
            bottom: 250,
            child: CustomLightBars(
              isLightOn: isLightOn,
            ),
          ),
          CustomBottomBar(
  onFileSelected: (fileName) async {
    setState(() {
      selectedFileName = fileName;
    });
    await uploadAudio(fileName);
  },

  audioPlayer: _audioPlayer,
  appStateProvider: appState,
  isVibrationOn: isVibrationOn,
),
        ],
      ),
    );
  }
}

class CustomLightBars extends StatefulWidget {
  final bool isLightOn;

  CustomLightBars({required this.isLightOn});

  @override
  _CustomLightBarsState createState() => _CustomLightBarsState();
}

class _CustomLightBarsState extends State<CustomLightBars> {
  double _lastAmplitude = 0.0;
  List<Color> barColors = List<Color>.filled(10, Colors.grey); // Cores padrão

  List<double> barHeights = [5.0, 8.0, 11.0, 14.0, 17.0, 20.0, 23.0, 26.0, 29.0, 32.0];

  late AppState appState;

  @override
  void initState() {
    super.initState();
    appState = Provider.of<AppState>(context, listen: false);
    _lastAmplitude = appState.amplitude_segmento;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Adicionar listener apenas para a variável amplitude_segmento
    appState.addListener(_updateBarsFromOutside);
  }

  @override
  void dispose() {
    // Remover listener ao descartar o widget
    appState.removeListener(_updateBarsFromOutside);
    super.dispose();
  }

  void updateBars(double amplitude) {
    if (!widget.isLightOn) {
      return; // Não faz nada se a luz estiver desligada
    }

    print('Update bars with amplitude: $amplitude');

    // Define os limiares para as mudanças de cor e as cores correspondentes
    final thresholds = [
      0.0001,
      0.035,
      0.045,
      0.06,
      0.07,
      0.08,
      0.09,
      0.10,
      0.11,
      0.12
    ]; // Valores de X, Y, Z, ...
    final colors = [
      Colors.lightGreenAccent,
      Colors.lightGreen,
      Colors.green,
      Colors.lime,
      Colors.yellowAccent,
      Colors.yellow,
      Colors.orange,
      Colors.deepOrange,
      Colors.red,
      Colors.redAccent,
    ];

    int colorIndex = -1;

    // Itera sobre os limiares e verifica as condições
    for (int i = 0; i < thresholds.length; i++) {
      if (amplitude > thresholds[i]) {
        colorIndex = i;
      }
    }

    // Atualiza a cor de todas as barras
    for (int j = 0; j < barColors.length; j++) {
      if (j <= colorIndex) {
        // Atualiza a cor das barras com índices menores ou iguais a colorIndex
        _updateBarColor(j, colors[colorIndex]);
      } else {
        // Atualiza a cor das barras com índices maiores que colorIndex para cinza
        _updateBarColor(j, Colors.grey);
      }
    }
  }

  void _updateBarColor(int index, Color color) {
    print('Updating color for bar $index to $color');
    barColors[index] = color;
  }

  void _updateBarsFromOutside() {
    double amplitude = appState.amplitude_segmento;
    if (amplitude != _lastAmplitude) {
      print('Atualizando barras com amplitude: $amplitude');
      updateBars(amplitude);
      _lastAmplitude = amplitude;
    }
  }

  @override
Widget build(BuildContext context) {
  return Center( // Centro da tela
    child: Container(
      width: MediaQuery.of(context).size.width,
      height: 200, // Ajuste a altura total do conjunto de barras
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: List.generate(
          10,
          (index) => Positioned(
            left: index * 36.0 +
                15, // Espaçamento horizontal do stack de barras -> X + Y -> X é o espaçamento, Y é o left da margem.
            bottom: 25,
            child: Container(
              width: 30, // Largura da barra
              height: widget.isLightOn
                  ? barHeights[index] * 5
                  : 5.0, // Altura de *CADA* barra
              decoration: BoxDecoration(
                color: widget.isLightOn ? barColors[index] : Colors.grey,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}

class CustomBottomBar extends StatefulWidget {
  final ValueChanged<String> onFileSelected;
  AudioPlayer audioPlayer;
  final AppState appStateProvider;
  final bool isVibrationOn;
  
  CustomBottomBar({super.key, 
    required this.onFileSelected,
    required this.audioPlayer,
    required this.appStateProvider,
    required this.isVibrationOn,
  });

  @override
  _CustomBottomBarState createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;
  late String filePath;
  bool isPlaying = false;
  Timer? _timer;
  bool _userIsMovingSlider = false;
  late double _maxSliderValue;

  @override
  void initState() {
    super.initState();
    filePath = "";
    _maxSliderValue = 1.0;

    _controller1 = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _controller2 = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250),
    );

    _controller3 = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _controller1.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller1.reverse();
      } else if (status == AnimationStatus.dismissed) {
        if (isPlaying) {
          _controller1.forward();
        }
      }
    });

    _controller2.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller2.reverse();
      } else if (status == AnimationStatus.dismissed) {
        if (isPlaying) {
          _controller2.forward();
        }
      }
    });

    _controller3.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller3.reverse();
      } else if (status == AnimationStatus.dismissed) {
        if (isPlaying) {
          _controller3.forward();
        }
      }
    });

    _controller1.forward();
    _controller2.forward();
    _controller3.forward();
  }

  void _toggleAnimation() {
    setState(() {
      isPlaying = !isPlaying;
    });

    if (isPlaying) {
      _controller1.forward();
      _controller2.forward();
      _controller3.forward();
    } else {
      _controller1.stop();
      _controller2.stop();
      _controller3.stop();
    }
  }

  void _playPause() {
  if (filePath== "") {
    showErrorSnackbar();
    return; // Retorna sem fazer mais nada se filePath for vazio
  }

  if (widget.audioPlayer.state == PlayerState.playing) {
    widget.audioPlayer.pause();
    _stopAmplitudeCheck();
    _stopVibrationAmplitudeCheck();
  } else {
    widget.audioPlayer.resume();
    _startAmplitudeCheck();
    _startVibrationAmplitudeCheck();
  }

  _toggleAnimation();
}
  void playPause() {
  _playPause();
}

  void showErrorSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nenhuma música selecionada'),
      ),
    );
  }

  void _startAmplitudeCheck() {
    final currentContext = context;
    final appStateProvider =
        Provider.of<AppState>(currentContext, listen: false);

    _timer = Timer.periodic(Duration(milliseconds: 300), (Timer timer) async {
      if (isPlaying && !_userIsMovingSlider) {
        final position = await widget.audioPlayer.getCurrentPosition();
        final state = widget.audioPlayer.state;

        if (position != null && state == PlayerState.completed) {
          print('Áudio atingiu o final');
          _stopAmplitudeCheck();
        } else if (position != null) {
          final amplitudeIndex = (position.inMilliseconds / 300).floor();
          if (amplitudeIndex >= 0 &&
              amplitudeIndex < appStateProvider.amplitudes.length) {
            final amplitudeValue = appStateProvider.amplitudes[amplitudeIndex];
            print('Amplitude for position $position: $amplitudeValue');
            // Atualizar valor de amplitude no Provider
            appStateProvider.updateAmplitude(amplitudeValue);
            
          }
        }
      }
    });
  }

  void _stopAmplitudeCheck() {
    _timer?.cancel();
  }

  void _startVibrationAmplitudeCheck() {
    final currentContext = context;
    final appStateProvider =
    Provider.of<AppState>(currentContext, listen: false);
    

    _timer = Timer.periodic(
        Duration(milliseconds: (appStateProvider.vibrationDuration).toInt()), //Teste de sincronização 08/02
        (Timer timer) async {
      if (isPlaying && !_userIsMovingSlider) {
        final position = await widget.audioPlayer.getCurrentPosition();
        final state = widget.audioPlayer.state;

        if (position != null && state == PlayerState.completed) {
          print('Áudio atingiu o final');
          _stopVibrationAmplitudeCheck();
        } else if (position != null) {
          final amplitudeIndex = (position.inMilliseconds /
                  appStateProvider.vibrationDuration.toInt())
              .floor();
          if (amplitudeIndex >= 0 &&
              amplitudeIndex < appStateProvider.vibrationAmplitudes.length) {
            final amplitudeValue =
                appStateProvider.vibrationAmplitudes[amplitudeIndex];
            print('Vibrando com amplitude: $amplitudeValue');
            print(
                'Vibrando com duração: ${appStateProvider.vibrationDuration}');
            if (!widget.isVibrationOn) return; // Não faz nada se a vibração estiver desligada
            Vibration.vibrate(
                duration: appStateProvider.vibrationDuration,
                amplitude: amplitudeValue.toInt());

            // Pode adicionar lógica adicional ou manipulações aqui conforme necessário
          }
        }
      }
    });
  }

  void _stopVibrationAmplitudeCheck() {
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 60,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        width: MediaQuery.of(context).size.width * 0.8,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.lightGreen.shade100,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.green.shade900,
                size: 50,
              ),
              onPressed: () {
                _playPause();
              },
            ),
            Container(
              margin: EdgeInsets.only(right: 20),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green.shade900, width: 2),
              ),
              child: IconButton(
                icon: Icon(Icons.cloud_upload, color: Colors.green.shade900),
                onPressed: () {
                  print('Botão de Upload pressionado');
                  _pickMp3File();
                },
              ),
            ),
            Row(
              children: [
                AnimatedBar(
                    controller: _controller1,
                    index: 1,
                    isPlaying: isPlaying,
                    delay: 0.0,
                    height: 50),
                SizedBox(width: 5),
                AnimatedBar(
                    controller: _controller2,
                    index: 2,
                    isPlaying: isPlaying,
                    delay: 0.0,
                    height: 50),
                SizedBox(width: 5),
                AnimatedBar(
                    controller: _controller3,
                    index: 3,
                    isPlaying: isPlaying,
                    delay: 0.34,
                    height: 50),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopAmplitudeCheck();
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  Future<void> _pickMp3File() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
    );

    if (result != null) {
      String newFilePath = result.files.single.path ?? "";
      print("Caminho do novo arquivo MP3: $newFilePath");

      // Se o filePath não estiver vazio, coloque a sourcedevicefile como a nova música e defina a posição para 00:00
      if (filePath.isNotEmpty) {
        // Configurar a nova música e definir a posição como 00:00
        if (widget.audioPlayer.state == PlayerState.playing){
          _playPause();} // Pausa a reprodução antes de selecionar um novo arquivo
        await widget.audioPlayer.setSourceDeviceFile(newFilePath);
        await widget.audioPlayer.seek(Duration(seconds: 0));
      } else {
        // Se o filePath estiver vazio, configurar normalmente sem alterar a posição
        await widget.audioPlayer.setSourceDeviceFile(newFilePath);
      }

      // Atualizar o filePath com o novo caminho
      filePath = newFilePath;

      // Notificar sobre a seleção do arquivo
      widget.onFileSelected(filePath);

      // Obter a duração do áudio e atualizar _maxSliderValue
      widget.audioPlayer.getDuration().then((duration) {
        setState(() {
          _maxSliderValue = duration?.inSeconds.toDouble() ?? 1.0;
        });
      });

      // _playPause(); // Inicia a reprodução após selecionar o arquivo
    } else {
      print("Nenhum arquivo MP3 selecionado.");
    }
  } catch (e) {
    print("Erro ao selecionar arquivo MP3: $e");
  }
}
}

class CustomSlider extends StatefulWidget {
  final AudioPlayer audioPlayer;
  

  CustomSlider({required this.audioPlayer,});

  @override
  _CustomSliderState createState() => _CustomSliderState();
}

class DurationState {
  const DurationState(
      {required this.progress, required this.buffered, required this.total});
  final Duration progress;
  final Duration buffered;
  final Duration total;
}

class _CustomSliderState extends State<CustomSlider> {
  late double _sliderValue;
  late double _maxSliderValue;
  bool _userIsMovingSlider = false;
  late Duration _duration; // Adicionado _duration aqui
  late StreamController<DurationState> _durationStateController;
  

  


  @override
  void initState() {
    super.initState();
    _sliderValue = 0.0;
    _maxSliderValue = 1.0;
    _duration = Duration.zero; // Inicializado _duration aqui

    _durationStateController = StreamController<DurationState>();

    widget.audioPlayer.onPositionChanged.listen((position) {
      if (position >= _duration - const Duration(milliseconds: 200)) {
        // Se o estado do player for completado, atualiza o slider e chama onComplete
        
        widget.audioPlayer.seek(Duration.zero);
    
         
        return;
      }
      final progress = position;
      final buffered = position;
      final total = _duration;

      final durationState = DurationState(
        progress: progress,
        buffered: buffered,
        total: total,
      );

      _durationStateController.add(durationState);

      setState(() {
        _sliderValue =
            position.inSeconds.toDouble().clamp(0.0, _maxSliderValue);
      });
    });

    widget.audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        _duration = duration;
        _maxSliderValue = duration.inSeconds.toDouble();
      });
    });

  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 150,
      left: 0,
      right: 0,
      child: StreamBuilder<DurationState>(
        stream: _durationStateController.stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: ProgressBar(
                  progress: Duration.zero,
                  buffered: Duration.zero,
                  total: Duration.zero,
                  progressBarColor: Colors.green.shade900,
                  bufferedBarColor: Colors.grey,
                  baseBarColor: Colors.grey[300],
                ));
          }
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 35),
            child: ProgressBar(
              progress: snapshot.data!.progress,
              total: snapshot.data!.total,
              onSeek: (duration) {
                setState(() {
                  _sliderValue = duration.inSeconds.toDouble();
                  _userIsMovingSlider = true;
                });
                widget.audioPlayer.seek(duration);
              },
              timeLabelLocation: TimeLabelLocation.below,
              thumbColor: Colors.green.shade900,
              thumbRadius: 8.0,
              progressBarColor: Colors.green.shade900,
              bufferedBarColor: Colors.grey,
              baseBarColor: Colors.grey[300],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _durationStateController.close();
    super.dispose();
  }
}

class AnimatedBar extends StatelessWidget {
  final AnimationController controller;
  final int index;
  final bool isPlaying;
  final double delay;
  final double height;

  AnimatedBar({
    required this.controller,
    required this.index,
    required this.isPlaying,
    required this.delay,
    required this.height,
  }) : super(key: ValueKey<int>(index));

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double animatedValue = (controller.value - delay).abs();
        double barHeight =
            (isPlaying ? (animatedValue * height).clamp(0.0, height) : height);
        return Container(
          width: 10,
          height: barHeight,
          margin: EdgeInsets.only(top: height - barHeight),
          decoration: BoxDecoration(
            color: Colors.green.shade900,
            borderRadius: BorderRadius.circular(5),
          ),
        );
      },
    );
  }
}