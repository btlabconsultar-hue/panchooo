import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../services/gemini_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _huggingFaceController = TextEditingController();
  final _apiFootballController = TextEditingController();
  AiProvider _provider = AiProvider.local;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final appState = context.read<AppState>();
    setState(() {
      _huggingFaceController.text = appState.aiService.huggingFaceApiKey;
      _apiFootballController.text = appState.sportsService.apiFootballKey;
      _provider = appState.aiService.selectedProvider;
    });
  }

  @override
  void dispose() {
    _huggingFaceController.dispose();
    _apiFootballController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Tema oscuro'),
              trailing: Switch(
                value: appState.themeMode == ThemeMode.dark,
                onChanged: (_) => appState.toggleTheme(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Central Deportiva'),
              subtitle: const Text(
                'Fútbol argentino y NBA con IA y datos en vivo',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Proveedor de IA',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RadioListTile<AiProvider>(
                    title: const Text('Respuesta local'),
                    subtitle: const Text(
                      'Sin pagar ni depender de servicios externos',
                    ),
                    value: AiProvider.local,
                    groupValue: _provider,
                    onChanged: (value) => setState(() {
                      _provider = value ?? AiProvider.local;
                    }),
                  ),
                  RadioListTile<AiProvider>(
                    title: const Text('Hugging Face'),
                    value: AiProvider.huggingFace,
                    groupValue: _provider,
                    onChanged: (value) => setState(() {
                      _provider = value ?? AiProvider.local;
                    }),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'La app responderá sin Gemini ni ChatGPT. Si no usás Hugging Face, se quedará con respuestas locales.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Clave Hugging Face',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _huggingFaceController,
                    decoration: const InputDecoration(
                      hintText: 'Hugging Face API Key',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Clave API-Football',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _apiFootballController,
                    decoration: const InputDecoration(
                      hintText: 'API-Football API Key',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: () async {
                          await appState.setKey(
                            _huggingFaceController.text.trim(),
                            AiProvider.huggingFace,
                          );
                          await appState.setApiFootballKey(
                            _apiFootballController.text.trim(),
                          );
                          await appState.setProvider(_provider);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Configuración guardada'),
                              ),
                            );
                          }
                        },
                        child: const Text('Guardar configuración'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () async {
                          final activeKey = _provider == AiProvider.huggingFace
                              ? _huggingFaceController.text.trim()
                              : '';
                          await appState.setKey(activeKey, _provider);
                          await appState.setProvider(_provider);

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                          try {
                            final answer = await appState.aiService.ask(
                              question: 'Prueba de conexión',
                              sport: appState.selectedSport,
                              league:
                                  appState.selectedLeague ??
                                  appState.footballLeagues.first,
                              matches: appState.matches,
                            );
                            if (mounted) Navigator.of(context).pop();
                            await showDialog<void>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Resultado de prueba'),
                                content: SingleChildScrollView(
                                  child: SelectableText(answer),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Cerrar'),
                                  ),
                                ],
                              ),
                            );
                          } catch (e) {
                            if (mounted) Navigator.of(context).pop();
                            await showDialog<void>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Error en prueba'),
                                content: SingleChildScrollView(
                                  child: SelectableText(e.toString()),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Cerrar'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        child: const Text('Probar proveedor'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Proveedor activo: ${_provider == AiProvider.huggingFace ? 'Hugging Face' : 'Respuesta local'}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
