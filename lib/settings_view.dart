import 'package:flutter/material.dart';
import 'models/settings.dart'; // Make sure to adjust the path if needed.

class SettingsView extends StatefulWidget {
  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  Settings? currentSettings;
  TextEditingController villageSpawnFrequencyController = TextEditingController();
  TextEditingController buildingLevelUpFrequencyController = TextEditingController();
  TextEditingController unitCreationFrequencyController = TextEditingController();
  TextEditingController unitTrainingFrequencyController = TextEditingController();
  TextEditingController attackFrequencyController = TextEditingController();
  TextEditingController costMultiplierController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    var settings = await Settings.getSettingsFromDB();
    if (settings != null) {
      setState(() {
        currentSettings = settings;
        villageSpawnFrequencyController.text = settings.villageSpawnFrequency.toString();
        buildingLevelUpFrequencyController.text = settings.buildingLevelUpFrequency.toString();
        unitCreationFrequencyController.text = settings.unitCreationFrequency.toString();
        unitTrainingFrequencyController.text = settings.unitTrainingFrequency.toString();
        attackFrequencyController.text = settings.attackFrequency.toString();
        costMultiplierController.text = settings.costMultiplier.toStringAsFixed(2);
      });
    }
  }

  _saveSettings() async {
    currentSettings!.villageSpawnFrequency = int.parse(villageSpawnFrequencyController.text);
    currentSettings!.buildingLevelUpFrequency = int.parse(buildingLevelUpFrequencyController.text);
    currentSettings!.unitCreationFrequency = int.parse(unitCreationFrequencyController.text);
    currentSettings!.unitTrainingFrequency = int.parse(unitTrainingFrequencyController.text);
    currentSettings!.attackFrequency = int.parse(attackFrequencyController.text);
    currentSettings!.costMultiplier = double.parse(costMultiplierController.text);
    await currentSettings!.updateSettings();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings View'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _settingsTextField("Village Spawn Frequency:", villageSpawnFrequencyController),
          _settingsTextField("Building Level Up Frequency:", buildingLevelUpFrequencyController),
          _settingsTextField("Unit Creation Frequency:", unitCreationFrequencyController),
          _settingsTextField("Unit Training Frequency:", unitTrainingFrequencyController),
          _settingsTextField("Attack Frequency:", attackFrequencyController),
          _settingsTextField("Cost Multiplier:", costMultiplierController),
          SizedBox(height: 20),
          ElevatedButton(onPressed: _saveSettings, child: Text('Save Settings')),
        ],
      ),
    );
  }

  Widget _settingsTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
    );
  }
}

