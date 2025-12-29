import 'package:flutter/material.dart';
import '../utils/theme.dart';

// --- 1. ADDRESS BOOK SCREEN (EMPTY STATE) ---
class AddressBookScreen extends StatelessWidget {
  const AddressBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Address Book", style: TextStyle(color: DivaraTheme.primaryColor, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: DivaraTheme.primaryColor),
        elevation: 0,
        backgroundColor: bgColor,
        actions: [
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AddAddressScreen())),
            child: const Text("Add New Address", style: TextStyle(color: DivaraTheme.primaryColor, decoration: TextDecoration.underline)),
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Stack (Location Pin)
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 100, color: Colors.grey.withOpacity(0.2)),
                  const Positioned(
                    top: 0,
                    child: Icon(Icons.location_on, size: 60, color: DivaraTheme.primaryColor),
                  ),
                  const Positioned(
                    top: 15,
                    child: Icon(Icons.priority_high, size: 30, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text("Oops!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 10),
              Text("You haven’t saved any addresses.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => const AddAddressScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D2E2E), // Dark Maroon Button
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Add New Address", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. ADD NEW ADDRESS FORM (MATCHING SCREENSHOT) ---
class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  // Controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _localityCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();

  String _addressType = "Home"; // 'Home' or 'Work'
  bool _isDefault = false;

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Add New Address", style: TextStyle(color: Color(0xFF5D2E2E), fontWeight: FontWeight.bold)), // Dark Maroon Title
        iconTheme: const IconThemeData(color: Color(0xFF5D2E2E)),
        elevation: 0,
        backgroundColor: bgColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- CONTACT DETAILS ---
                  _sectionHeader("Contact Details"),
                  const SizedBox(height: 15),
                  _buildTextField("First Name*", _firstNameCtrl),
                  const SizedBox(height: 15),
                  _buildTextField("Last Name*", _lastNameCtrl),
                  const SizedBox(height: 15),
                  
                  // Mobile Number Row
                  Row(
                    children: [
                      Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.flag, color: Colors.orange, size: 18),
                            SizedBox(width: 5),
                            Text("+91", style: TextStyle(fontWeight: FontWeight.bold)),
                            Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey)
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField("Mobile No.*", _mobileCtrl, isNumber: true),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // --- ADDRESS SECTION ---
                  _sectionHeader("Address"),
                  const SizedBox(height: 15),

                  // Country (Static)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("India", style: TextStyle(fontSize: 16)),
                        Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 15),
                  _buildTextField("Pin Code*", _pinCtrl, isNumber: true),
                  const SizedBox(height: 15),
                  _buildTextField("Address*", _addressCtrl),
                  const SizedBox(height: 15),
                  _buildTextField("Locality/ Town", _localityCtrl),
                  const SizedBox(height: 15),
                  
                  // City & State Row
                  Row(
                    children: [
                      Expanded(child: _buildTextField("City*", _cityCtrl)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildTextField("State*", _stateCtrl)),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // --- SAVE AS SECTION ---
                  _sectionHeader("Save As"),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildTypeButton("Home"),
                      const SizedBox(width: 15),
                      _buildTypeButton("Work"),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Default Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _isDefault,
                        activeColor: const Color(0xFF5D2E2E),
                        onChanged: (v) => setState(() => _isDefault = v!),
                      ),
                      const Text("Set as default address", style: TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  
                  const SizedBox(height: 20), // Extra space for scrolling
                ],
              ),
            ),
          ),
          
          // --- BOTTOM BUTTON ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Address Added Successfully!")));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D2E2E), // Matches screenshot button color
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("Add Address", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      color: Colors.grey.withOpacity(0.1), // Light grey background strip
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade400)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade400)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF5D2E2E))),
      ),
    );
  }

  Widget _buildTypeButton(String type) {
    bool isSelected = _addressType == type;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() => _addressType = type),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: isSelected ? const Color(0xFF5D2E2E) : Colors.grey.shade400),
          backgroundColor: isSelected ? Colors.white : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(
          type, 
          style: TextStyle(
            color: isSelected ? const Color(0xFF5D2E2E) : Colors.grey, 
            fontWeight: FontWeight.bold
          )
        ),
      ),
    );
  }
}