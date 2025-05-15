import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

void main() {
  runApp(const MahjongApp());
}

class MahjongApp extends StatelessWidget {
  const MahjongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mahjong 胡牌 Simulator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const SimulatorScreen(),
    );
  }
}

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  // Simulation parameters
  int _selectedTileCount = 5; // Default to 5 tiles. Use 0 for "All"
  int _numberOfSamples = 1000; // Default number of samples
  final TextEditingController _samplesController = TextEditingController(text: '1000');
  bool _isRunning = false;
  // bool _isPaused = false; // Removed, not suitable for sample-based simulation

  // Simulation results for individual tile counts
  Map<int, SimulationStats> _statsMap = {
    5: SimulationStats(),
    8: SimulationStats(),
    11: SimulationStats(),
  };
  int _currentSimulationStage = 0; // For 'All' mode: 5, 8, or 11. Or the selected tile count.

  // Overall simulation results (used for single mode, or current stage in 'All' mode)
  // These might be derived from _statsMap or directly updated.
  // For now, let's keep them for the single mode display and potentially for current stage display.
  int _totalHands = 0;
  int _validHands = 0;
  double _probability = 0.0;
  List<SimulationResult> _lastValidHands = [];
  List<SimulationResult> _lastInvalidHands = [];

  // Timer? _simulationTimer; // Removed
  bool get _isWeb => identical(0, 0.0);

  @override
  void initState() {
    super.initState();
    _samplesController.addListener(() {
      final newSamples = int.tryParse(_samplesController.text);
      if (newSamples != null && newSamples > 0) {
        setState(() {
          _numberOfSamples = newSamples;
        });
      }
    });
  }

  @override
  void dispose() {
    _stopSimulation(); // Ensure any running simulation is flagged to stop
    _samplesController.dispose();
    super.dispose();
  }

  void _resetSimulationData() {
    setState(() {
      _totalHands = 0;
      _validHands = 0;
      _probability = 0.0;
      _lastValidHands = [];
      _lastInvalidHands = [];
      _statsMap = {
        5: SimulationStats(),
        8: SimulationStats(),
        11: SimulationStats(),
      };
      _currentSimulationStage = 0;
    });
  }

  Future<void> _runSimulationBatch(int tileCount, int samples) async {
    if (!_isRunning) return;

    setState(() {
      _currentSimulationStage = tileCount;
      // Reset stats for the current specific tile count if it's a single run
      // or ensure the specific map entry is clean for an 'All' run stage.
      if (_selectedTileCount != 0) { // Single mode run
        _statsMap[tileCount]?.reset();
        _totalHands = 0;
        _validHands = 0;
        _probability = 0.0;
        _lastValidHands = [];
        _lastInvalidHands = [];
      }
    });

    final random = Random();
    for (int i = 0; i < samples; i++) {
      if (!_isRunning) break; // Check if simulation was stopped

      final hand = List.generate(tileCount, (_) => random.nextInt(9) + 1);
      final isValid = MahjongValidator.isValidHand(hand);
      
      // Update stats for the specific tile count
      _statsMap[tileCount]?.recordHand(hand, isValid);

      // If in single mode, also update the general display variables
      if (_selectedTileCount != 0) {
          _totalHands = _statsMap[tileCount]!.totalHands;
          _validHands = _statsMap[tileCount]!.validHands;
          _probability = _statsMap[tileCount]!.probability;
          _lastValidHands = _statsMap[tileCount]!.lastValidHands;
          _lastInvalidHands = _statsMap[tileCount]!.lastInvalidHands;
      }

      if (i % 100 == 0) { // Update UI periodically and allow event loop to process
        setState(() {});
        await Future.delayed(Duration.zero); // Yield to event loop
      }
    }
    // Final update for the current batch
    setState(() {});
  }

  Future<void> _startSimulation() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _resetSimulationData(); 
    });

    if (_selectedTileCount == 0) { // "All" mode
      for (int tileCount in [5, 8, 11]) {
        if (!_isRunning) break;
        await _runSimulationBatch(tileCount, _numberOfSamples);
      }
    } else { // Single tile count mode
      await _runSimulationBatch(_selectedTileCount, _numberOfSamples);
    }

    if (mounted) { // Check if the widget is still in the tree
      setState(() {
        _isRunning = false;
        if (_selectedTileCount != 0 && _statsMap.containsKey(_selectedTileCount)){
            _totalHands = _statsMap[_selectedTileCount]!.totalHands;
            _validHands = _statsMap[_selectedTileCount]!.validHands;
            _probability = _statsMap[_selectedTileCount]!.probability;
            _lastValidHands = _statsMap[_selectedTileCount]!.lastValidHands;
            _lastInvalidHands = _statsMap[_selectedTileCount]!.lastInvalidHands;
        }
        _currentSimulationStage = 0; // Reset stage indicator
      });
    }
  }

  // void _pauseSimulation() { // Removed
  // }

  void _stopSimulation() {
    setState(() {
      _isRunning = false; // This flag will be checked by _runSimulationBatch
      // _isPaused = false; // Removed
    });
  }

  void _resetSimulation() {
    _stopSimulation();
    _resetSimulationData();
  }

  // void _startSimulationTimer() { // Removed
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mahjong 胡牌 Simulator'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tile Count Selection & Number of Samples
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Simulation Settings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('Tile Count:'),
                    Row(
                      children: [
                        Radio<int>(
                          value: 5,
                          groupValue: _selectedTileCount,
                          onChanged: _isRunning
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedTileCount = value!;
                                  });
                                },
                        ),
                        const Text('5'),
                        Radio<int>(
                          value: 8,
                          groupValue: _selectedTileCount,
                          onChanged: _isRunning
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedTileCount = value!;
                                  });
                                },
                        ),
                        const Text('8'),
                        Radio<int>(
                          value: 11,
                          groupValue: _selectedTileCount,
                          onChanged: _isRunning
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedTileCount = value!;
                                  });
                                },
                        ),
                        const Text('11'),
                        Radio<int>(
                          value: 0, // Using 0 for "All"
                          groupValue: _selectedTileCount,
                          onChanged: _isRunning
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedTileCount = value!;
                                  });
                                },
                        ),
                        const Text('All (5,8,11)'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Number of Samples:'),
                    TextField(
                      controller: _samplesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Enter number of samples',
                      ),
                      enabled: !_isRunning,
                    ),
                  ],
                ),
              ),
            ),
            // Simulation Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Simulation Controls',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(_isRunning ? Icons.hourglass_empty : Icons.play_circle_filled),
                          label: Text(_isRunning ? 'Simulating...' : 'Start Simulation'),
                          onPressed: _isRunning ? null : _startSimulation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRunning ? Colors.grey : Colors.green,
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('Stop'),
                          onPressed: _isRunning ? _stopSimulation : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh_outlined),
                          label: const Text('Reset'),
                          onPressed: _isRunning ? null : _resetSimulation,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Statistics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Statistics',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_isRunning && _selectedTileCount == 0 && _currentSimulationStage != 0)
                      Text('Simulating for $_currentSimulationStage tiles... Sample ${_statsMap[_currentSimulationStage]?.totalHands ?? 0}/$_numberOfSamples'),
                    
                    if (_selectedTileCount != 0) ...[ // Single mode display
                      _buildStatItem('Total Hands', _totalHands.toString()),
                      _buildStatItem('Valid Hands', _validHands.toString()),
                      _buildStatItem('Probability', _totalHands > 0 ? '${_probability.toStringAsFixed(2)}%' : '0.00%'),
                    ] else if (_selectedTileCount == 0) ...[ // "All" mode display
                      if (!_isRunning && _statsMap[5]!.totalHands == 0 && _statsMap[8]!.totalHands == 0 && _statsMap[11]!.totalHands == 0) ...[
                        const Text('Run simulation to see stats for All (5, 8, 11).'),
                      ] else ...[
                        for (var tc in [5, 8, 11])
                          if (_statsMap[tc]!.totalHands > 0 || (_isRunning && _currentSimulationStage == tc)) 
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$tc Tiles Results${_isRunning && _currentSimulationStage == tc && _statsMap[tc]!.totalHands < _numberOfSamples ? " (running... ${_statsMap[tc]!.totalHands}/$_numberOfSamples)" : ""}:',
                                    style: const TextStyle(fontWeight: FontWeight.bold)
                                  ),
                                  Text('  Total Hands: ${_statsMap[tc]!.totalHands}'),
                                  Text('  Valid Hands: ${_statsMap[tc]!.validHands}'),
                                  Text('  Probability: ${_statsMap[tc]!.probability.toStringAsFixed(2)}%'),
                                ],
                              ),
                            ),
                      ]
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Last Hands (Valid and Invalid)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Last 3 Valid Hands
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Last 3 Valid Hands (胡牌)',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: (_selectedTileCount != 0 && _lastValidHands.isEmpty && !(_statsMap.values.any((s) => s.lastValidHands.isNotEmpty))) || 
                                     (_selectedTileCount == 0 && !_statsMap.values.any((s) => s.lastValidHands.isNotEmpty))
                                  ? const Center(child: Text('No valid hands yet'))
                                  : ListView(
                                      children: _selectedTileCount != 0 
                                        ? _lastValidHands.map<Widget>((r) => ListTile(title: Text(r.hand.join(' ')), trailing: const Text('胡牌 ✅', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)))).toList()
                                        : [5, 8, 11].expand<Widget>((tc) {
                                            if (_statsMap[tc]!.lastValidHands.isNotEmpty) {
                                              return [
                                                Padding(padding: const EdgeInsets.only(top: 8.0, bottom: 4.0), child: Text('$tc Tiles:', style: const TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold))),
                                                ..._statsMap[tc]!.lastValidHands.map((r) => ListTile(title: Text(r.hand.join(' ')), trailing: const Text('胡牌 ✅', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))))
                                              ];
                                            }
                                            return [];
                                          }).toList(),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Last 3 Invalid Hands
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Last 3 Invalid Hands (非胡牌)',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: (_selectedTileCount != 0 && _lastInvalidHands.isEmpty && !(_statsMap.values.any((s) => s.lastInvalidHands.isNotEmpty))) ||
                                     (_selectedTileCount == 0 && !_statsMap.values.any((s) => s.lastInvalidHands.isNotEmpty))
                                  ? const Center(child: Text('No invalid hands yet'))
                                  : ListView(
                                      children: _selectedTileCount != 0
                                        ? _lastInvalidHands.map<Widget>((r) => ListTile(title: Text(r.hand.join(' ')), trailing: const Text('非胡牌 ❌', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))).toList()
                                        : [5, 8, 11].expand<Widget>((tc) {
                                            if (_statsMap[tc]!.lastInvalidHands.isNotEmpty) {
                                              return [
                                                Padding(padding: const EdgeInsets.only(top: 8.0, bottom: 4.0), child: Text('$tc Tiles:', style: const TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold))),
                                                ..._statsMap[tc]!.lastInvalidHands.map((r) => ListTile(title: Text(r.hand.join(' ')), trailing: const Text('非胡牌 ❌', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))))
                                              ];
                                            }
                                            return [];
                                          }).toList(),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// Data Models

class SimulationResult {
  final List<int> hand;
  final bool isValid;

  SimulationResult(this.hand, this.isValid);
}

// Mahjong Validation Logic
class MahjongValidator {
  static bool isValidHand(List<int> hand) {
    // Sort the hand for easier processing
    final sortedHand = List<int>.from(hand)..sort();
    
    // Check based on tile count
    if (hand.length == 5) {
      // 5 tiles: 1 meld + 1 pair
      return _checkHandStructure(sortedHand, 1, 1);
    } else if (hand.length == 8) {
      // 8 tiles: 2 melds + 1 pair
      return _checkHandStructure(sortedHand, 2, 1);
    } else if (hand.length == 11) {
      // 11 tiles: 3 melds + 1 pair
      return _checkHandStructure(sortedHand, 3, 1);
    }
    
    return false;
  }

  static bool _checkHandStructure(List<int> hand, int melds, int pairs) {
    // Try all possible ways to form the required structure
    return _findValidCombination(List<int>.from(hand), melds, pairs);
  }

  static bool _findValidCombination(List<int> remainingTiles, int melds, int pairs) {
    // Base case: if we've used all required melds and pairs
    if (melds == 0 && pairs == 0) {
      // Check if all tiles are used
      return remainingTiles.isEmpty;
    }
    
    // If no tiles left but we still need melds or pairs, invalid
    if (remainingTiles.isEmpty) {
      return false;
    }
    
    // Try to form a pair if needed
    if (pairs > 0) {
      // Find all possible pairs
      for (int i = 0; i < remainingTiles.length - 1; i++) {
        if (remainingTiles[i] == remainingTiles[i + 1]) {
          // Remove the pair and continue
          final newRemaining = List<int>.from(remainingTiles);
          newRemaining.removeAt(i + 1);
          newRemaining.removeAt(i);
          
          // Recursively check if the remaining tiles can form the required structure
          if (_findValidCombination(newRemaining, melds, pairs - 1)) {
            return true;
          }
        }
      }
    }
    
    // Try to form a meld if needed
    if (melds > 0) {
      // Try to form a triplet (three of the same)
      for (int i = 0; i < remainingTiles.length - 2; i++) {
        if (remainingTiles[i] == remainingTiles[i + 1] && 
            remainingTiles[i] == remainingTiles[i + 2]) {
          // Remove the triplet and continue
          final newRemaining = List<int>.from(remainingTiles);
          newRemaining.removeAt(i + 2);
          newRemaining.removeAt(i + 1);
          newRemaining.removeAt(i);
          
          // Recursively check
          if (_findValidCombination(newRemaining, melds - 1, pairs)) {
            return true;
          }
        }
      }
      
      // Try to form a sequence (three consecutive numbers)
      for (int i = 0; i < remainingTiles.length; i++) {
        final first = remainingTiles[i];
        final second = first + 1;
        final third = first + 2;
        
        // Check if the sequence exists in the remaining tiles
        if (remainingTiles.contains(second) && remainingTiles.contains(third)) {
          // Remove the sequence and continue
          final newRemaining = List<int>.from(remainingTiles);
          newRemaining.remove(first);
          newRemaining.remove(second);
          newRemaining.remove(third);
          
          // Recursively check
          if (_findValidCombination(newRemaining, melds - 1, pairs)) {
            return true;
          }
        }
      }
    }
    
    // If we've tried all possibilities and none worked, return false
    return false;
  }
}

// Helper class for storing simulation statistics
class SimulationStats {
  int totalHands = 0;
  int validHands = 0;
  double probability = 0.0;
  List<SimulationResult> lastValidHands = [];
  List<SimulationResult> lastInvalidHands = [];

  void reset() {
    totalHands = 0;
    validHands = 0;
    probability = 0.0;
    lastValidHands = [];
    lastInvalidHands = [];
  }

  void recordHand(List<int> hand, bool isValid) {
    totalHands++;
    final result = SimulationResult(hand, isValid);
    if (isValid) {
      validHands++;
      lastValidHands.insert(0, result);
      if (lastValidHands.length > 3) {
        lastValidHands.removeLast();
      }
    } else {
      lastInvalidHands.insert(0, result);
      if (lastInvalidHands.length > 3) {
        lastInvalidHands.removeLast();
      }
    }
    if (totalHands > 0) {
      probability = validHands / totalHands * 100;
    }
  }
}
