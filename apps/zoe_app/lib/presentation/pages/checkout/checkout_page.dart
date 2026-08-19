import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/zoe_colors.dart';
import '../../../core/theme/zoe_typography.dart';
import '../../../core/theme/zoe_spacing.dart';
import '../../cubits/cart/cart_cubit.dart';
import '../../cubits/cart/cart_state.dart';
import '../../cubits/checkout/checkout_cubit.dart';
import '../../cubits/address/address_cubit.dart';

/// CheckoutPage — fluxo de finalização do pedido.
///
/// Referência: ARCHITECTURE.md §8.3: Compensação Transacional (Checkout Seguro)
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _selectedPayment = 'pix';
  final _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = context.watch<CartCubit>().state;
    final addressState = context.watch<AddressCubit>().state;

    final items = cartState is CartLoaded ? cartState.items : [];
    final subtotal = cartState is CartLoaded ? cartState.subtotal : 0.0;
    final deliveryFee = 12.90;
    final total = subtotal + deliveryFee;

    final addressLabel = addressState is AddressSelected
        ? addressState.address.label
        : 'Selecione um endereço';

    return Scaffold(
      backgroundColor: ZoeColors.background,
      appBar: AppBar(
        title: Text('CHECKOUT', style: ZoeTypography.headlineSmall.copyWith(letterSpacing: 2)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocListener<CheckoutCubit, CheckoutState>(
        listener: (context, state) {
          if (state is CheckoutSuccess) {
            context.read<CartCubit>().clearCart();
            context.go('/order-success/${state.order.id}');
          } else if (state is CheckoutError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: items.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 64, color: ZoeColors.textSecondary),
                    const SizedBox(height: 16),
                    Text('Carrinho vazio', style: ZoeTypography.bodyLarge.copyWith(color: ZoeColors.textSecondary)),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(ZoeSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address Section
                    _SectionCard(
                      title: 'ENDEREÇO DE ENTREGA',
                      icon: Icons.location_on_outlined,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(addressLabel, style: ZoeTypography.bodyMedium),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to address selection
                            },
                            child: const Text('ALTERAR'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: ZoeSpacing.md),

                    // Items Summary
                    _SectionCard(
                      title: 'ITENS (${items.length})',
                      icon: Icons.shopping_bag_outlined,
                      child: Column(
                        children: items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    color: ZoeColors.surface,
                                    child: item.imageUrl != null
                                        ? Image.network(item.imageUrl!, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 20))
                                        : const Icon(Icons.image, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.productName, style: ZoeTypography.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text('${item.size} · ${item.color} · Qtd: ${item.quantity}',
                                          style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Text('R\$ ${item.totalPrice.toStringAsFixed(2)}', style: ZoeTypography.labelMedium),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: ZoeSpacing.md),

                    // Payment Method
                    _SectionCard(
                      title: 'PAGAMENTO',
                      icon: Icons.payment_outlined,
                      child: Column(
                        children: [
                          _PaymentOption(
                            label: 'PIX',
                            subtitle: 'Desconto de 5%',
                            icon: Icons.qr_code,
                            value: 'pix',
                            groupValue: _selectedPayment,
                            onChanged: (v) => setState(() => _selectedPayment = v!),
                          ),
                          _PaymentOption(
                            label: 'Cartão de Crédito',
                            subtitle: 'Até 12x sem juros',
                            icon: Icons.credit_card,
                            value: 'credit_card',
                            groupValue: _selectedPayment,
                            onChanged: (v) => setState(() => _selectedPayment = v!),
                          ),
                          _PaymentOption(
                            label: 'Cartão de Débito',
                            subtitle: 'Débito on-line',
                            icon: Icons.credit_card_outlined,
                            value: 'debit_card',
                            groupValue: _selectedPayment,
                            onChanged: (v) => setState(() => _selectedPayment = v!),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: ZoeSpacing.md),

                    // Coupon
                    _SectionCard(
                      title: 'CUPOM',
                      icon: Icons.local_offer_outlined,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _couponController,
                              decoration: InputDecoration(
                                hintText: 'Código do cupom',
                                hintStyle: ZoeTypography.bodySmall.copyWith(color: ZoeColors.textSecondary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              context.read<CheckoutCubit>().setCoupon(_couponController.text);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ZoeColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('APLICAR'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: ZoeSpacing.lg),

                    // Price Summary
                    Container(
                      padding: EdgeInsets.all(ZoeSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _PriceRow(label: 'Subtotal', value: 'R\$ ${subtotal.toStringAsFixed(2)}'),
                          _PriceRow(label: 'Entrega', value: 'R\$ ${deliveryFee.toStringAsFixed(2)}'),
                          const Divider(height: 24),
                          _PriceRow(label: 'Total', value: 'R\$ ${total.toStringAsFixed(2)}', isBold: true),
                        ],
                      ),
                    ),
                    SizedBox(height: ZoeSpacing.lg),

                    // Place Order button
                    BlocBuilder<CheckoutCubit, CheckoutState>(
                      builder: (context, checkoutState) {
                        final isProcessing = checkoutState is CheckoutProcessing;
                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ZoeColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: ZoeColors.primary.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: isProcessing || addressState is! AddressSelected
                                ? null
                                : () {
                                    final cartItems = (cartState as CartLoaded).items;
                                    context.read<CheckoutCubit>().placeOrder(
                                      items: cartItems,
                                      addressId: (addressState).address.id,
                                      paymentMethod: _selectedPayment,
                                      couponCode: _couponController.text.isNotEmpty ? _couponController.text : null,
                                    );
                                  },
                            child: isProcessing
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(
                                    'FINALIZAR PEDIDO',
                                    style: ZoeTypography.labelLarge.copyWith(color: Colors.white, letterSpacing: 1.5),
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ZoeSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: ZoeColors.primary),
              const SizedBox(width: 8),
              Text(title, style: ZoeTypography.labelMedium.copyWith(letterSpacing: 1.2, color: ZoeColors.textSecondary)),
            ],
          ),
          SizedBox(height: ZoeSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _PaymentOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeColor: ZoeColors.primary,
      title: Row(
        children: [
          Icon(icon, size: 20, color: ZoeColors.textPrimary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: ZoeTypography.bodyMedium),
              Text(subtitle, style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _PriceRow({required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isBold ? ZoeTypography.labelLarge : ZoeTypography.bodyMedium),
          Text(value, style: isBold ? ZoeTypography.labelLarge.copyWith(color: ZoeColors.primary) : ZoeTypography.bodyMedium),
        ],
      ),
    );
  }
}
