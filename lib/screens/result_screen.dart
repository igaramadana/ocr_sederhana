import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ocr_sederhana/screens/home_screen.dart';

class ResultScreen extends StatefulWidget {
  final String ocrText;

  const ResultScreen({super.key, required this.ocrText});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late FlutterTts flutterTts;
  bool _isSpeaking = false;
  bool _isTtsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    flutterTts = FlutterTts();

    // Konfigurasi TTS
    await flutterTts.setLanguage("id-ID");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(1.0);

    // Handler untuk events TTS
    flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        _isSpeaking = false;
      });
      _showSnackBar('Error TTS: $msg');
    });

    setState(() {
      _isTtsInitialized = true;
    });
  }

  Future<void> _speakText() async {
    if (widget.ocrText.isEmpty) {
      _showSnackBar('Tidak ada teks untuk dibacakan');
      return;
    }

    if (!_isTtsInitialized) {
      _showSnackBar('TTS belum siap, tunggu sebentar...');
      return;
    }

    if (_isSpeaking) {
      await _stopSpeaking();
      return;
    }

    try {
      await flutterTts.speak(widget.ocrText);
    } catch (e) {
      _showSnackBar('Gagal memulai pembacaan teks: $e');
    }
  }

  Future<void> _stopSpeaking() async {
    try {
      await flutterTts.stop();
      setState(() {
        _isSpeaking = false;
      });
    } catch (e) {
      _showSnackBar('Gagal menghentikan pembacaan');
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  void _copyToClipboard() {
    if (widget.ocrText.isEmpty) {
      _showSnackBar('Tidak ada teks untuk disalin');
      return;
    }

    Clipboard.setData(ClipboardData(text: widget.ocrText));
    _showSnackBar('Teks berhasil disalin!');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Tutup',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (!_isTtsInitialized) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sync, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              'Menyiapkan TTS...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (_isSpeaking) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.volume_up, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              'Sedang Membaca',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTtsButton() {
    if (!_isTtsInitialized) {
      return IconButton(
        icon: const Icon(Icons.volume_up, color: Colors.grey),
        onPressed: null,
        tooltip: 'TTS sedang disiapkan...',
      );
    }

    if (_isSpeaking) {
      return IconButton(
        icon: const Icon(Icons.stop, color: Colors.white),
        onPressed: _stopSpeaking,
        tooltip: 'Hentikan Pembacaan',
      );
    }

    return IconButton(
      icon: const Icon(Icons.volume_up, color: Colors.white),
      onPressed: _speakText,
      tooltip: 'Bacakan Teks',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil OCR'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (widget.ocrText.isNotEmpty) _buildTtsButton(),
          if (widget.ocrText.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white),
              onPressed: _copyToClipboard,
              tooltip: 'Salin Teks',
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
        ),
        child: Column(
          children: [
            // Header informasi
            Container(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.ocrText.isEmpty
                          ? Icons.warning
                          : Icons.check_circle,
                      color: widget.ocrText.isEmpty
                          ? Colors.orange
                          : Colors.green,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.ocrText.isEmpty
                                ? 'Tidak ada teks ditemukan'
                                : 'Teks berhasil dipindai',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.ocrText.isNotEmpty)
                            const SizedBox(height: 4),
                          if (widget.ocrText.isNotEmpty)
                            Text(
                              '${widget.ocrText.split(' ').length} kata • ${widget.ocrText.length} karakter',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (widget.ocrText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${widget.ocrText.split(' ').length} kata',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Header teks hasil scan dengan status TTS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Teks Hasil Scan:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          _buildStatusIndicator(),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Container teks hasil scan
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: widget.ocrText.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.text_fields,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Tidak ada teks yang terdeteksi',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : SelectableText(
                                    widget.ocrText,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.6,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.justify,
                                  ),
                          ),
                        ),
                      ),

                      // Tombol aksi
                      if (widget.ocrText.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            // Tombol Salin
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _copyToClipboard,
                                icon: const Icon(Icons.copy_rounded),
                                label: const Text('Salin Teks'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Tombol TTS
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _speakText,
                                icon: Icon(
                                  _isSpeaking
                                      ? Icons.stop_rounded
                                      : Icons.volume_up_rounded,
                                ),
                                label: Text(
                                  _isSpeaking ? 'Berhenti' : 'Dengarkan',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isSpeaking
                                      ? Colors.red
                                      : Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Floating Action Button untuk TTS
          if (widget.ocrText.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton(
                onPressed: _speakText,
                backgroundColor: _isSpeaking ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                heroTag: 'tts_button',
                child: Icon(
                  _isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                  size: 28,
                ),
              ),
            ),
          // Floating Action Button untuk Home
          FloatingActionButton(
            onPressed: () {
              if (_isSpeaking) {
                _stopSpeaking();
              }
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            heroTag: 'home_button',
            child: const Icon(Icons.home_rounded, size: 28),
          ),
        ],
      ),
    );
  }
}
