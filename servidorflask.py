from flask import Flask, jsonify, request
from flask_cors import CORS
import librosa
import numpy as np

app = Flask(__name__)
CORS(app)
def generate_vibration_amplitude(vibration_amplitudes, amplitude):
    if amplitude < 0.03:
        vibration_amplitudes.append(10.0)
    elif 0.03 <= amplitude <= 0.15:
        # Mapeamento proporcional
        mapped_value = map_value(amplitude, 0.03, 0.15, 10.0, 230.0)
        vibration_amplitudes.append(mapped_value)
    else:
        vibration_amplitudes.append(255.0)

def map_value(value, in_min, in_max, out_min, out_max):
     return int((value - in_min) * (out_max - out_min) / (in_max - in_min) + out_min)


def calculate_bpm_and_amplitudes(file_path):
    try:
        y, sr = librosa.load(file_path)
        duration = librosa.get_duration(y=y, sr=sr)

        # Calcular BPM para a música inteira
        bpm, _ = librosa.beat.beat_track(y=y, sr=sr)

        # Inicializar lista para armazenar as amplitudes a cada 0,5 segundos
        amplitudes = []

        # Loop sobre cada 0,3 segundos
        for i in range(0, int(duration / 0.3)):
            start = int(i * 0.3 * sr)
            end = int((i + 1) * 0.3 * sr)
            segment = y[start:end]
            amplitude = np.sqrt(np.mean(np.square(segment)))
            amplitudes.append(amplitude) 

        # Determinar a duração dos intervalos com base na faixa de BPM
        if 0 <= bpm <= 40:
            interval_duration = np.linspace(0.3, 0.45, num=20, endpoint=False)[int(bpm / 2)]
        elif 40 < bpm <= 70:
            interval_duration = np.linspace(0.45, 0.6, num=30, endpoint=False)[int((bpm - 40) / 2)]
        elif 70 < bpm <= 90:
            interval_duration = np.linspace(0.6, 0.75, num=40, endpoint=False)[int((bpm - 70) / 2)]
        elif 90 < bpm <= 110:
            interval_duration = np.linspace(0.75, 0.9, num=40, endpoint=False)[int((bpm - 90) / 2)]
        elif 110 < bpm <= 130:
            interval_duration = np.linspace(1.05, 1.4, num=20, endpoint=False)[int((bpm - 110) / 2)]
        elif 130 < bpm <= 150:
            interval_duration = np.linspace(1.4, 1.6, num=50, endpoint=False)[int((bpm - 130) / 2)]
        elif 150 < bpm <= 170:
            interval_duration = np.linspace(1.6, 1.8, num=50, endpoint=False)[int((bpm - 150) / 2)]
        elif 170 < bpm <= 190:
            interval_duration = np.linspace(1.8, 2.0, num=50, endpoint=False)[int((bpm - 170) / 2)]
        elif 190 < bpm <= 210:
            interval_duration = np.linspace(2.0, 2.2, num=30, endpoint=False)[int((bpm - 190) / 2)]
        else:
            interval_duration = 3.0

        # Inicializar lista para armazenar as amplitudes da vibração
        vibration_amplitudes = []

        # Loop sobre cada intervalo de duração
        for i in range(0, int(duration / interval_duration)):
            start = int(i * interval_duration * sr)
            end = int((i + 1) * interval_duration * sr)
            segment = y[start:end]
            amplitude = np.sqrt(np.mean(np.square(segment)))

            # Adicionar lógica para gerar amplitudes de vibração conforme as condições
            generate_vibration_amplitude(vibration_amplitudes, amplitude)

        # Retornar resultados
        return {
            'bpm': bpm,
            'amplitudes': [float(a) for a in amplitudes],
            'vibration_amplitudes': [int(a) for a in vibration_amplitudes],
            'interval_duration': int(interval_duration * 1000)  # Convertendo para milissegundos e depois para inteiro
        }

    except Exception as e:
        return {'error': str(e)}

@app.route('/', methods=['POST'])
def upload_audio():
    try:
        if 'file' not in request.files:
            return jsonify({'error': 'No file part'})

        file = request.files['file']

        if file.filename == '':
            return jsonify({'error': 'No selected file'})

        result = calculate_bpm_and_amplitudes(file)
        return jsonify(result)

    except Exception as e:
        print(f"Erro interno no servidor: {str(e)}")
        return jsonify({'error': 'Internal Server Error'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)




""" Servidor deve pegar a BPM média da música inteira

As amplitudes devem ser calculadas a cada 0,5seg

Duração da Vibração (em segundos):

Muito Curto (0.1 - 0.2 segundos): Para batidas extremamente rápidas.
Curto (0.2 - 0.4 segundos): Para batidas rápidas ou ritmos intensos.
Médio Curto (0.4 - 0.6 segundos): Para ritmos moderados com alguma intensidade.
Médio (0.6 - 0.8 segundos): Para músicas com ritmo moderado.
Médio Longo (0.8 - 1.0 segundos): Para ritmos moderados com alguma lentidão.
Longo Médio (1.0 - 1.5 segundos): Para músicas com batidas mais lentas.
Longo (1.5 - 2.0 segundos): Para seções mais lentas ou notas sustentadas.
Muito Longo (2.0 - 2.5 segundos): Para transições prolongadas.
Extra Longo (2.5 - 3.0 segundos): Para transições mais prolongadas.
Muito Extra Longo (3 segundos ou mais): Para transições extremamente prolongadas ou pausas.

BPM (batidas por minuto):

Muito Fraco (0 - 40 BPM): Muito lento, adequado para baladas extremamente lentas.  (0.1 - 0.2 segundos) Duração
Fraco (40 - 70 BPM): Lento, adequado para baladas e músicas relaxantes. (0.2 - 0.4 segundos) Duração
Moderado Fraco (70 - 90 BPM): Ritmo moderado, lento. (0.4 - 0.6 segundos) Duração
Moderado (90 - 110 BPM): Ritmo moderado, comum em muitos estilos musicais. (0.6 - 0.8 segundos) Duração
Moderado Alto (110 - 130 BPM): Ritmo moderado, rápido. (0.8 - 1.0 segundos) Duração
Alto Moderado (130 - 150 BPM): Ritmo rápido, comum em estilos mais acelerados. (1.0 - 1.5 segundos) Duração
Alto (150 - 170 BPM): Ritmo rápido, adequado para músicas energéticas. (1.5 - 2.0 segundos) Duração
Muito Alto (170 - 190 BPM): Muito rápido, comum em música eletrônica, rock rápido, etc. (2.0 - 2.5 segundos) Duração
Extra Alto (190 - 210 BPM): Ritmo extremamente rápido. (2.5 - 2.8 segundos) Duração
Muito Extra Alto (210 BPM ou mais): Muito rápido, adequado para estilos musicais extremamente acelerados. (3 segundos) Duração

Amplitude (Intensidade):  ---> amplitude RMS (Root Mean Square)

Muito Baixa (0 - 0.05): Vibração quase imperceptível.
Baixa (0.05 - 0.15): Vibração suave, mais sutil.
Média Baixa (0.15 - 0.25): Intensidade moderada, perceptível.
Média (0.25 - 0.35): Intensidade moderada a forte.
Média Alta (0.35 - 0.45): Intensidade forte, bastante perceptível.
Alta (0.45 - 0.55): Vibração forte, muito perceptível.
Muito Alta (0.55 - 0.65): Vibração intensa, bastante perceptível.
Extra Alta (0.65 - 0.75): Vibração muito intensa.
Muito Extra Alta (0.75 - 0.85): Vibração extremamente intensa.
Extremamente Alta (0.85 - 1): Vibração máxima, muito intensa.

https://github.com/kroger/books/blob/master/README.md

https://github.com/kroger/books/raw/master/MusicforGeeksandNerds.epub
Essa lógica assume que a lista de amplitudes está sincronizada com a posição de reprodução, e cada elemento na lista corresponde a uma posição 
específica em intervalos de 0,5 segundos. Certifique-se de que a lista de amplitudes tenha os valores corretos e esteja na ordem certa."""