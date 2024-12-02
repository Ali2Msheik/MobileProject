import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parking Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const TimerScreen(),
    );
  }
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final List<TimerItem> timers = [];
  final List<double> completedPrices = [];
  final TextEditingController textController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  bool isSearching = false; // To manage the visibility of the search box
  int _idCounter = 0;
  List<String> activeAlarms = [];

  double calculatePrice(int minutes) {
    const double ratePerMinute = 0.05;
    return minutes * ratePerMinute;
  }

  String generateUniqueId() {
    _idCounter++;
    return '${DateTime.now().millisecondsSinceEpoch}$_idCounter';
  }

  Color getRandomColor() {
    final randomIndex = Random().nextInt(Colors.primaries.length);
    return Colors.primaries[randomIndex];
  }

  void addTimer(String name, int minutes) {
    // Check if the timer name already exists
    if (timers.any((timer) => timer.name.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This timer name already exists. Please try a different name.'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Prevent adding the timer if the name already exists
    }
    final id = generateUniqueId();
    final price = calculatePrice(minutes);
    final color = getRandomColor();
    final timer = TimerItem(
      key: UniqueKey(),
      id: id,
      name: name,
      minutes: minutes,
      price: price,
      color: color,
      onDelete: () => removeTimer(id, price, name),
      onComplete: () {
        setState(() {
          if (!activeAlarms.contains(name)) {
            activeAlarms.add(name);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name timer completed!')),
        );
      },
      onReverseTick: (additionalPrice) {
        setState(() {
          completedPrices.add(additionalPrice);
        });
      },
    );
    setState(() {
      timers.add(timer);
    });
  }

  void removeTimer(String id, double price, String name) {
    setState(() {
      completedPrices.add(price);
      timers.removeWhere((timer) => timer.id == id);
      activeAlarms.remove(name);
    });
  }

  double calculateTotalAmount() {
    double ongoingTotal = timers.fold(0.0, (total, timer) => total + timer.price);
    double completedTotal = completedPrices.fold(0.0, (total, price) => total + price);
    return ongoingTotal + completedTotal;
  }

  void resetTimers() {
    setState(() {
      timers.clear();
      completedPrices.clear();
      activeAlarms.clear();
      nameController.clear();
      textController.clear();
      priceController.clear();
      _idCounter = 0;
      searchController.clear();
      isSearching = false; // Reset search state
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredTimers = timers.where((timer) => timer.name.toLowerCase().contains(searchController.text.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Timer'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search functionality on the left side
            Row(
              children: [
                IconButton(
                  icon: Icon(isSearching ? Icons.close : Icons.search),
                  onPressed: () {
                    setState(() {
                      isSearching = !isSearching; // Toggle search box visibility
                      if (!isSearching) searchController.clear(); // Clear search when closing
                    });
                  },
                ),
                Expanded(
                  child: isSearching
                      ? TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by timer name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) {
                      setState(() {}); // Update the UI when text changes
                    },
                  )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (activeAlarms.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.red[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🔔 Timer Active: ${activeAlarms.join(", ")}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: Row(
                children: [
                  // Left Side: Input Fields
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 40,
                          child: TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              hintText: 'Enter timer name',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 40,
                          child: TextField(
                            controller: textController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Enter time (minutes)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (value) {
                              final minutes = int.tryParse(value);
                              if (minutes != null) {
                                final price = calculatePrice(minutes);
                                priceController.text = '\$${price.toStringAsFixed(2)}';
                              } else {
                                priceController.clear();
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 40,
                          child: TextField(
                            controller: priceController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: 'Price will appear here',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            final name = nameController.text.trim();
                            final minutes = int.tryParse(textController.text);
                            if (name.isNotEmpty && minutes != null) {
                              addTimer(name, minutes);
                              textController.clear();
                              nameController.clear();
                              priceController.clear();
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Timer'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: resetTimers,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset Timers'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red, // Red background
                            foregroundColor: Colors.amberAccent,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text( 'Total Amount:',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '\$${calculateTotalAmount().toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right Side: Timers List
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredTimers.length,
                            itemBuilder: (context, index) {
                              return filteredTimers[index];
                            },
                          ),
                        ),
                        // Message when no timers are found
                        if (filteredTimers.isEmpty && isSearching)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Timer not found',
                              style: TextStyle(fontSize: 16, color: Colors.red),
                            ),
                          ),
                      ],
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
}

class TimerItem extends StatefulWidget {
  final String id;
  final String name;
  final int minutes;
  final double price;
  final Color color;
  final VoidCallback onDelete;
  final VoidCallback onComplete;
  final ValueChanged<double> onReverseTick;

  const TimerItem({
    super.key,
    required this.id,
    required this.name,
    required this.minutes,
    required this.price,
    required this.color,
    required this.onDelete,
    required this.onComplete,
    required this.onReverseTick,
  });

  @override
  State<TimerItem> createState() => _TimerItemState();
}

class _TimerItemState extends State<TimerItem> {
  late int timeLeft;
  Timer? timer;
  double currentPrice = 0.0;
  static const double ratePerMinute = 0.05; // Standard rate per minute

  static const double feePerMinute = 0.06; // Overdue rate per minute
  int lastOverdueMinute = 0; // Tracks the last overdue minute processed

  @override
  void initState() {
    super.initState();
    timeLeft = widget.minutes * 60;
    currentPrice = widget.price;
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
        });
      } else {
        if (timeLeft == 0) widget.onComplete();
        setState(() {
          timeLeft--;
        });
        if (timeLeft.abs() % 60 == 0) {
          widget.onReverseTick(ratePerMinute);
        }
        if (timeLeft < 0) {
          // Handle overdue pricing
          applyOverduePenalty();
        }
      }
    });
  }

  // Apply penalty for overdue time
  void applyOverduePenalty() {
    final overdueMinutes = (timeLeft.abs() / 60).floor(); // Full overdue minutes
    if (overdueMinutes > lastOverdueMinute) {
      setState(() {
        currentPrice += ratePerMinute; // Apply ratePerMinute for each overdue minute
        widget.onReverseTick(ratePerMinute); // Update total
      });
      lastOverdueMinute = overdueMinutes;
    }
  }

  void addAdditionalTime(int minutes) {
    setState(() {
      // Determine rate to apply based on whether timer is overdue
      final rate = timeLeft < 0 ? feePerMinute : ratePerMinute;
      final additionalPrice = minutes * rate;
      currentPrice += additionalPrice;
      timeLeft += minutes * 60; // Add additional time in seconds
      widget.onReverseTick(additionalPrice); // Update total
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          timeLeft < 0
              ? 'Added $minutes minutes to ${widget.name} (+\$${(minutes * feePerMinute).toStringAsFixed(2)})'
              : 'Added $minutes minutes to ${widget.name} (+\$${(minutes * ratePerMinute).toStringAsFixed(2)})',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayText;
    if (timeLeft > 0) {
      displayText = 'Time Left: ${timeLeft ~/ 60}:${(timeLeft % 60).toString().padLeft(2, '0')}';
    } else {
      displayText = 'Overdue: ${timeLeft.abs() ~/ 60}:${(timeLeft.abs() % 60).toString().padLeft(2, '0')}';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: timeLeft > 0 ? widget.color.withOpacity(0.2) : Colors.red[100],
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: widget.color,
          child: Text(widget.name[0].toUpperCase()),
        ),
        title: Text(
          '${widget.name} - $displayText',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Price: \$${currentPrice.toStringAsFixed(2)}',
          style: TextStyle(
            color: timeLeft > 0 ? Colors.black : Colors.red[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.green),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    final TextEditingController additionalTimeController = TextEditingController();
                    return AlertDialog(
                      title: const Text('Add Time'),
                      content: TextField(
                        controller: additionalTimeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Enter additional minutes',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final additionalMinutes = int.tryParse(additionalTimeController.text);
                            if (additionalMinutes != null && additionalMinutes > 0) {
                              addAdditionalTime(additionalMinutes);
                              Navigator.of(context).pop();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a valid number of minutes.'),
                                ),
                              );
                            }
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.delete,
                color: timeLeft > 0 ? Colors.red : Colors.grey[700],
              ),
              onPressed: widget.onDelete,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}