import 'dart:async';
import 'package:flutter/material.dart';
import '../models/script_request.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storyController = TextEditingController();
  final _apiService = ApiService();

  String _selectedStyle = 'modern_clean';
  final Map<String, String> _styles = {
    'modern_clean': 'Modern Clean',
    'manga_bw': 'Manga B&W',
    'pixar_3d': '3D Animated (Pixar-ish)',
    'watercolor_storybook': 'Watercolor Storybook',
    'retro_american': 'Retro American',
  };

  String _selectedNuance = 'adventure';
  final Map<String, String> _nuances = {
    'adventure': 'Petualangan',
    'comedy': 'Komedi',
    'drama': 'Drama',
    'mystery': 'Misteri',
    'horror_light': 'Horror Ringan',
    'romance_light': 'Romantis Ringan',
    'education': 'Edukasi',
  };

  bool _isLoading = false;
  String _statusMessage = '';
  String? _jobId;
  Timer? _pollingTimer;
  Map<String, dynamic>? _jobResult;

  @override
  void dispose() {
    _storyController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }
  
  void _startPolling(String jobId) {
    setState(() {
      _jobId = jobId;
      _isLoading = true;
      _statusMessage = 'Sedang menggambar... (Job ID: $jobId)';
    });

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
       final result = await _apiService.checkJobStatus(jobId);
       final status = result['status'];
       
       setState(() {
         // Update status text
         if (status == 'queued') _statusMessage = 'Antrian...';
         else if (status == 'rendering_part_1') _statusMessage = 'Menggambar Bagian 1/2...';
         else if (status == 'rendering_part_2') _statusMessage = 'Menggambar Bagian 2/2...';
         else if (status == 'done') {
           _statusMessage = 'Selesai!';
           _isLoading = false;
           _jobResult = result;
           timer.cancel(); // Stop polling
         } else if (status == 'error') {
           _statusMessage = 'Gagal: ${result['error']}';
           _isLoading = false;
           timer.cancel();
         }
       });
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _statusMessage = 'Membuat Naskah & Karakter...';
      _jobResult = null;
    });

    try {
      // 1. Generate Script
      final req = ScriptRequest(
        story: _storyController.text,
        styleId: _selectedStyle,
        nuances: [_selectedNuance],
      );
      
      final scriptResponse = await _apiService.generateScript(req);
      final scriptData = scriptResponse['script'];
      
      setState(() {
        _statusMessage = 'Naskah siap. Mulai render gambar...';
      });
      
      // 2. Start Render
      final jobId = await _apiService.renderAllStart(scriptData);
      
      // 3. Poll Status
      _startPolling(jobId);
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
      
      showDialog(
        context: context, 
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            )
          ],
        )
      );
    }
  }

  Future<void> _openPdf() async {
    if (_jobId == null) return;
    // Construct PDF URL
    // If backend returns a public Cloud Storage URL via redirect, we can open it directly.
    // Or access /api/pdf/{jobId}?download=0
    
    final url = Uri.parse('${AppConstants.baseUrl}/api/pdf/$_jobId');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch PDF URL')),
      );
    }
  }
  
  // Helper to build image URL with cache busting or just direct
  // Note: in early implementation, /api/preview/{job_id}/{part} returned image bytes. 
  // If cloud mode redirects to GCS, Image.network handles it fine.
  String _getPartUrl(int part) {
    return '${AppConstants.baseUrl}/api/preview/$_jobId/$part';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nano Banana Comic'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             // Input Form
             Card(
               elevation: 2,
               child: Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Form(
                   key: _formKey,
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text('Buat Komik Baru', style: Theme.of(context).textTheme.titleLarge),
                       const SizedBox(height: 16),
                       
                       TextFormField(
                         controller: _storyController,
                         maxLines: 4,
                         decoration: const InputDecoration(
                           labelText: 'Ide Cerita',
                           hintText: 'Contoh: Kancil mencuri timun di kebun Pak Tani tapi ketahuan...',
                           border: OutlineInputBorder(),
                           alignLabelWithHint: true,
                         ),
                         validator: (v) => (v == null || v.isEmpty) ? 'Cerita tidak boleh kosong' : null,
                       ),
                       const SizedBox(height: 16),
                       
                       DropdownButtonFormField<String>(
                         value: _selectedStyle,
                         decoration: const InputDecoration(
                           labelText: 'Gaya Gambar (Style)',
                           border: OutlineInputBorder(),
                         ),
                         items: _styles.entries.map((e) => DropdownMenuItem(
                           value: e.key,
                           child: Text(e.value),
                         )).toList(),
                         onChanged: (v) => setState(() => _selectedStyle = v!),
                       ),
                       const SizedBox(height: 16),
                       
                       DropdownButtonFormField<String>(
                         value: _selectedNuance,
                         decoration: const InputDecoration(
                           labelText: 'Nuansa (Mood)',
                           border: OutlineInputBorder(),
                         ),
                         items: _nuances.entries.map((e) => DropdownMenuItem(
                           value: e.key,
                           child: Text(e.value),
                         )).toList(),
                         onChanged: (v) => setState(() => _selectedNuance = v!),
                       ),
                       const SizedBox(height: 24),
                       
                       SizedBox(
                         width: double.infinity,
                         height: 50,
                         child: ElevatedButton(
                           onPressed: _isLoading ? null : _submit,
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Theme.of(context).colorScheme.primary,
                             foregroundColor: Colors.white,
                           ),
                           child: _isLoading 
                             ? const CircularProgressIndicator(color: Colors.white) 
                             : const Text('GENERATE COMIC ✨', style: TextStyle(fontWeight: FontWeight.bold)),
                         ),
                       ),
                       if (_statusMessage.isNotEmpty)
                         Padding(
                           padding: const EdgeInsets.only(top: 12.0),
                           child: Text(
                             _statusMessage, 
                             textAlign: TextAlign.center,
                             style: TextStyle(
                               color: _statusMessage.startsWith('Gagal') ? Colors.red : Colors.blue
                             ),
                           ),
                         ),
                     ],
                   ),
                 ),
               ),
             ),
             
             const SizedBox(height: 24),
             
             // Result Section
             if (_jobResult != null && _jobId != null) ...[
                Text('Hasil Komik:', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                
                // PDF Button
                if (_jobResult?['has_pdf'] == true)
                  ElevatedButton.icon(
                    onPressed: _openPdf, 
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Buka PDF Komik'),
                  ),
                  
                const SizedBox(height: 16),
                
                // Image Previews
                if (_jobResult?['has_preview_part1'] == true) ...[
                   const Text('Bagian 1:'),
                   const SizedBox(height: 8),
                   Image.network(
                     _getPartUrl(1),
                     loadingBuilder: (ctx, child, progress) {
                       if (progress == null) return child;
                       return const Center(child: CircularProgressIndicator());
                     },
                     errorBuilder: (ctx, err, stack) => const Text('Gagal memuat gambar part 1'),
                   ),
                   const SizedBox(height: 16),
                ],
                
                if (_jobResult?['has_preview_part2'] == true) ...[
                   const Text('Bagian 2:'),
                   const SizedBox(height: 8),
                   Image.network(
                     _getPartUrl(2),
                     loadingBuilder: (ctx, child, progress) {
                       if (progress == null) return child;
                       return const Center(child: CircularProgressIndicator());
                     },
                     errorBuilder: (ctx, err, stack) => const Text('Gagal memuat gambar part 2'),
                   ),
                ]
             ],
          ],
        ),
      ),
    );
  }
}
