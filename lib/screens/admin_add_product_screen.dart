import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

class AdminAddProductScreen extends StatefulWidget {
  const AdminAddProductScreen({super.key});

  @override
  State<AdminAddProductScreen> createState() => _AdminAddProductScreenState();
}

class _AdminAddProductScreenState extends State<AdminAddProductScreen> {
  // --- UI Control Variables ---
  bool isFormOpen = false; // ફોર્મ ખુલ્લું છે કે લિસ્ટ?
  String? editingDocId; // જો Edit કરતા હોય તો ID

  // --- Form Controllers ---
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();
  final TextEditingController stockCtrl = TextEditingController(); // 🔥 Stock
  final TextEditingController descCtrl = TextEditingController();
  final TextEditingController weightCtrl = TextEditingController();
  final TextEditingController sizeCtrl = TextEditingController();
  String selectedCategory = "";

  bool isUploading = false;
  List<XFile> _selectedImages = [];
  List<dynamic> _existingImages = [];
  final ImagePicker _picker = ImagePicker();

  // 🔥 ફોર્મ ખોલવા અથવા બંધ કરવા માટેનું ફંક્શન
  void toggleForm({Map<String, dynamic>? product, String? docId}) {
    setState(() {
      isFormOpen = !isFormOpen;
      editingDocId = docId;
      if (product != null) {
        // Edit Mode: ડેટા ભરો
        nameCtrl.text = product['name'] ?? "";
        priceCtrl.text = (product['price'] ?? "").toString();
        stockCtrl.text = (product['stock'] ?? 0).toString(); // 🔥 Stock
        descCtrl.text = product['description'] ?? "";
        weightCtrl.text = product['weight'] ?? "";
        sizeCtrl.text = product['size'] ?? "";
        selectedCategory = product['category'] ?? "";
        _existingImages =
            product['images'] ??
            (product['image'] != null ? [product['image']] : []);
      } else {
        // Add Mode: ફોર્મ ખાલી કરો
        nameCtrl.clear();
        priceCtrl.clear();
        stockCtrl.clear(); // 🔥 Stock
        descCtrl.clear();
        weightCtrl.clear();
        sizeCtrl.clear();
        _selectedImages = [];
        _existingImages = [];
        selectedCategory = "";
      }
    });
  }

  // 🔥 ImgBB Upload Function
  Future<String?> _uploadToImgBB(File imageFile) async {
    String apiKey = "13f5ec1a72d4d0d691e96d18d8cc0731";
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.imgbb.com/1/upload'),
    );
    request.fields['key'] = apiKey;
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );
    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.toBytes();
      var json = jsonDecode(String.fromCharCodes(responseData));
      return json['data']['url'];
    }
    return null;
  }

  // 🔥 Save Data to Firebase
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty && _existingImages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Select images!")));
      return;
    }

    setState(() => isUploading = true);
    try {
      List<String> finalUrls = List.from(_existingImages);
      for (var img in _selectedImages) {
        String? url = await _uploadToImgBB(File(img.path));
        if (url != null) finalUrls.add(url);
      }

      Map<String, dynamic> data = {
        'name': nameCtrl.text.trim(),
        'price': int.tryParse(priceCtrl.text.trim()) ?? 0,
        'stock': int.tryParse(stockCtrl.text.trim()) ?? 0, // 🔥 Added Stock
        'category': selectedCategory,
        'image': finalUrls.isNotEmpty ? finalUrls.first : "",
        'images': finalUrls,
        'description': descCtrl.text.trim(),
        'weight': weightCtrl.text.trim(),
        'size': sizeCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (editingDocId == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('products').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(editingDocId)
            .update(data);
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Success!")));
      toggleForm(); // લિસ્ટ પર પાછા જાઓ
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isUploading = false);
    }
  }

  // 🔥 Delete Confirmation Dialog
  void _confirmDelete(Map<String, dynamic> product, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Product?"),
        content: Text("Are you sure you want to delete '${product['name']}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: const Text("NO", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await FirebaseFirestore.instance
                  .collection('products')
                  .doc(docId)
                  .delete();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Product Deleted Successfully")),
                );
              }
            },
            child: const Text(
              "YES, DELETE",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF9C8270)),
            ),
          );
        }

        var categoryDocs = snapshot.data!.docs;
        List<String> dynamicCategories = categoryDocs
            .map((doc) => doc['name'].toString())
            .toList();

        // If currently selected category (for form) is not in new list, reset it
        if (!dynamicCategories.contains(selectedCategory) &&
            dynamicCategories.isNotEmpty) {
          selectedCategory = dynamicCategories.first;
        }

        return DefaultTabController(
          length: dynamicCategories.length,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(
                isFormOpen
                    ? (editingDocId == null ? "Add Product" : "Edit Product")
                    : "Admin Panel",
              ),
              backgroundColor: const Color(0xFF9C8270),
              leading: isFormOpen
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => toggleForm(),
                    )
                  : null,
              bottom: isFormOpen
                  ? null
                  : TabBar(
                      isScrollable: true,
                      indicatorColor: Colors.white,
                      tabs: dynamicCategories.map((c) => Tab(text: c)).toList(),
                    ),
            ),

            floatingActionButton: isFormOpen
                ? null
                : FloatingActionButton(
                    backgroundColor: const Color(0xFF9C8270),
                    child: const Icon(Icons.add, color: Colors.white),
                    onPressed: () => toggleForm(),
                  ),

            body: isFormOpen
                ? _buildForm(dynamicCategories)
                : TabBarView(
                    children: dynamicCategories
                        .map((cat) => _buildProductList(cat))
                        .toList(),
                  ),
          ),
        );
      },
    );
  }

  // --- UI: Category Wise List ---
  // (Removed _buildTabbedList as it is now inline)

  Widget _buildProductList(String category) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: category)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No products found"));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            String docId = docs[index].id;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: ListTile(
                leading: CachedNetworkImage(
                  imageUrl: data['image'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  memCacheWidth: 100, // 🔥 Optimization for List
                  errorWidget: (c, e, s) => const Icon(Icons.image),
                ),
                title: Text(
                  data['name'] ?? "",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("₹${data['price']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => toggleForm(product: data, docId: docId),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(data, docId),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- UI: Add/Edit Form ---
  Widget _buildForm(List<String> dynamicCategories) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Images Grid
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._existingImages.map(
                    (url) => _imagePreview(url: url, isNetwork: true),
                  ),
                  ..._selectedImages.map(
                    (file) => _imagePreview(file: file, isNetwork: false),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final List<XFile> imgs = await _picker.pickMultiImage();
                      if (imgs.isNotEmpty)
                        setState(() => _selectedImages.addAll(imgs));
                    },
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_a_photo),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(nameCtrl, "Product Name", Icons.shopping_bag),
            _buildTextField(
              priceCtrl,
              "Price",
              Icons.currency_rupee,
              isNumber: true,
            ),
            _buildTextField(
              stockCtrl,
              "Available Units (Stock)",
              Icons.inventory_2,
              isNumber: true,
            ),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Category",
              ),
              items: dynamicCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => selectedCategory = val!),
            ),

            const SizedBox(height: 10),
            _buildTextField(
              descCtrl,
              "Description",
              Icons.description,
              maxLines: 3,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(weightCtrl, "Weight", Icons.scale),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(sizeCtrl, "Size", Icons.straighten),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isUploading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C8270),
                ),
                child: isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "SAVE CHANGES",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePreview({String? url, XFile? file, required bool isNetwork}) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 10),
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
              image: isNetwork
                  ? CachedNetworkImageProvider(url!)
                  : FileImage(File(file!.path)) as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => setState(
              () => isNetwork
                  ? _existingImages.remove(url)
                  : _selectedImages.remove(file),
            ),
            child: Container(
              color: Colors.red,
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: (v) => v!.isEmpty ? "Required" : null,
      ),
    );
  }
}
