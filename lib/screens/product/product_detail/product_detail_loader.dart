import 'package:flutter/material.dart';
import 'package:gizmoglobe_client/data/database/database.dart';
import 'package:gizmoglobe_client/screens/product/product_detail/product_detail_webview.dart';

class ProductDetailLoader extends StatefulWidget {
  final String productId;

  const ProductDetailLoader({super.key, required this.productId});

  @override
  State<ProductDetailLoader> createState() => _ProductDetailLoaderState();
}

class _ProductDetailLoaderState extends State<ProductDetailLoader> {
  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final product = await Database().getProductByID(widget.productId);
    if (!mounted) return;

    if (product == null) {
      // Product not found, navigate to products page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/products');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Database().getProductByID(widget.productId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          // Show loading while redirecting
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return ProductDetailScreenWebView.newInstance(snapshot.data!);
      },
    );
  }
}
