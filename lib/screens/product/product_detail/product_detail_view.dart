import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gizmoglobe_client/screens/product/product_detail/product_detail_cubit.dart';
import 'package:gizmoglobe_client/screens/product/product_detail/product_detail_state.dart';
import 'package:gizmoglobe_client/widgets/general/gradient_icon_button.dart';
import 'package:intl/intl.dart';

import '../../../objects/product_related/cpu.dart';
import '../../../objects/product_related/drive.dart';
import '../../../objects/product_related/gpu.dart';
import '../../../objects/product_related/mainboard.dart';
import '../../../objects/product_related/product.dart';
import '../../../objects/product_related/psu.dart';
import '../../../objects/product_related/ram.dart';


class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  static Widget newInstance(Product product) => BlocProvider(
        create: (context) => ProductDetailCubit(product),
        child: ProductDetailScreen(product: product),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: GradientIconButton(
          icon: Icons.chevron_left,
          onPressed: () => Navigator.pop(context),
          fillColor: Colors.transparent,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // Implement share functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.favorite_border),
            onPressed: () {
              // Implement wishlist functionality
            },
          ),
        ],
        title: BlocBuilder<ProductDetailCubit, ProductDetailState>(
          builder: (context, state) => Text(
            state.product.productName,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      body: BlocBuilder<ProductDetailCubit, ProductDetailState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image Section - smaller size
                Container(
                  height: MediaQuery.of(context).size.height * 0.25,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                  ),
                  child: Image.network(
                    'https://ramleather.vn/wp-content/uploads/2022/07/woocommerce-placeholder-200x200-1.jpg',
                    fit: BoxFit.contain,
                  ),
                ),
                
                // Product Info Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information Section
                      Text(
                        'Basic Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[300],
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      _buildInfoRow(
                        icon: Icons.inventory_2,
                        title: 'Product',
                        value: product.productName,
                      ),
                      
                      _buildInfoRow(
                        icon: Icons.category,
                        title: 'Category',
                        value: product.category.toString().split('.').last,
                      ),
                      
                      _buildInfoRow(
                        icon: Icons.business,
                        title: 'Manufacturer',
                        value: product.manufacturer.manufacturerName,
                      ),
                      
                      // Thêm thông tin về giá và discount
                      _buildPriceSection(
                        sellingPrice: product.price,
                        discount: product.discount,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Status Information Section
                      Text(
                        'Status Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[300],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          _buildStatusChip(product.status),
                          SizedBox(width: 16),
                          Icon(
                            product.stock > 0 ? Icons.check_circle : Icons.error,
                            color: product.stock > 0 ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Stock: ${product.stock}',
                            style: TextStyle(
                              color: product.stock > 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 8),
                      _buildInfoRow(
                        icon: Icons.calendar_today,
                        title: 'Release Date',
                        value: DateFormat('dd/MM/yyyy').format(product.release),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Technical Specifications Section
                      Text(
                        'Technical Specifications',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[300],
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      ..._buildProductSpecificDetails(context, product, state.technicalSpecs),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(dynamic status) {
    // Xác định màu sắc dựa trên status
    Color chipColor;
    Color textColor;
    
    switch(status.toString().toLowerCase()) {
      case 'active':
        chipColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        break;
      case 'inactive':
        chipColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        break;
      case 'pending':
        chipColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        break;
      default:
        chipColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toString(),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          SizedBox(width: 8),
          Text(
            '$title: ',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProductSpecificDetails(
    BuildContext context, 
    Product product,
    Map<String, String> specs
  ) {
    return specs.entries.map((entry) => 
      _buildSpecificationRow(entry.key, entry.value)
    ).toList();
  }

  Widget _buildSpecificationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection({
    required double sellingPrice,
    required double discount,
  }) {
    final discountedPrice = sellingPrice * (1 - discount);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.attach_money, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 8),
          const Text(
            'Price: ',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          if (discount > 0) ...[
            Text(
              '\$${sellingPrice.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
                decoration: TextDecoration.lineThrough,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '\$${discountedPrice.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.green[300],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '-${(discount * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.red[300],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else
            Text(
              '\$${sellingPrice.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }
}