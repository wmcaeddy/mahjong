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
  int _selectedTileCount = 5; // Default to 5 tiles
  bool _isRunning = false;
  bool _isPaused = false;
  
  // Simulation results
  int _totalHands = 0;
  int _validHands = 0;
  double _probability = 0.0;
  List<SimulationResult> _lastResults = [];
  
  // Timer for simulation
  Timer? _simulationTimer;
  bool get _isWeb => identical(0, 0.0);

  @override
  void dispose() {
    _stopSimulation();
    super.dispose();
  }

  void _startSimulation() {
    if (_isRunning && !_isPaused) return;
    
    if (_isPaused) {
      setState(() {
        _isPaused = false;
        _isRunning = true;
      });
      
      // Resume timer
      _startSimulationTimer();
      return;
    }
    
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    
    _startSimulationTimer();
  }

  void _pauseSimulation() {
    if (!_isRunning || _isPaused) return;
    
    setState(() {
      _isPaused = true;
    });
    
    _simulationTimer?.cancel();
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    
    setState(() {
      _isRunning = false;
      _isPaused = false;
    });
  }

  void _resetSimulation() {
    _stopSimulation();
    setState(() {
      _totalHands = 0;
      _validHands = 0;
      _probability = 0.0;
      _lastResults = [];
    });
  }

  void _startSimulationTimer() {
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isPaused) {
        timer.cancel();
        return;
      }
      
      // Generate a random hand
      final random = Random();
      final hand = List.generate(
        _selectedTileCount,
        (_) => random.nextInt(9) + 1, // 1-9 tiles
      );
      
      // Check if it's a valid hand
      final isValid = MahjongValidator.isValidHand(hand);
      final result = SimulationResult(hand, isValid);
      
      setState(() {
        _totalHands++;
        if (isValid) _validHands++;
        _probability = _validHands / _totalHands * 100;
        
        // Keep only last 3 results
        _lastResults.insert(0, result);
        if (_lastResults.length > 3) {
          _lastResults.removeLast();
        }
      });
    });
  }

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
            // Tile Count Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tile Count Selection',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
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
                        const Text('5 Tiles'),
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
                        const Text('8 Tiles'),
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
                        const Text('11 Tiles'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Control Buttons
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
                          onPressed: _isRunning && !_isPaused ? null : _startSimulation,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Run'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isRunning && !_isPaused ? _pauseSimulation : null,
                          icon: const Icon(Icons.pause),
                          label: const Text('Pause'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isRunning ? _resetSimulation : null,
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop'),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Total Hands', _totalHands.toString()),
                        _buildStatItem('Valid Hands', _validHands.toString()),
                        _buildStatItem(
                          'Probability',
                          _totalHands > 0
                              ? '${_probability.toStringAsFixed(2)}%'
                              : '0.00%',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Last 3 Hands
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last 3 Hands',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _lastResults.isEmpty
                            ? const Center(child: Text('No hands simulated yet'))
                            : ListView.builder(
                                itemCount: _lastResults.length,
                                itemBuilder: (context, index) {
                                  final result = _lastResults[index];
                                  return ListTile(
                                    title: Text(
                                      result.hand.join(' '),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    trailing: result.isValid
                                        ? const Text(
                                            '胡牌 ✅',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : const Text(
                                            '非胡牌 ❌',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  );
                                },
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
