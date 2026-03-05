import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product_model.dart';
import '../database/database_helper.dart';
import 'order_history_screen.dart';

class PaymentScreen extends StatefulWidget {
  final List<Product> cartItems;
  final double total;
  final VoidCallback onPaymentComplete;

  const PaymentScreen({
    super.key,
    required this.cartItems,
    required this.total,
    required this.onPaymentComplete,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  // ── Controladores ────────────────────────────────────────────────────────
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _promoCtrl = TextEditingController();

  // ── Estado ───────────────────────────────────────────────────────────────
  String _selectedMethod = 'Credit';
  bool _saveCard = false;
  bool _promoApplied = false;
  double _discount = 0;
  bool _isProcessing = false;
  int _currentStep = 0; // 0 = datos tarjeta, 1 = confirmación

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  final List<String> _methods = ['PayPal', 'Credit', 'Wallet'];

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim =
        Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _holderCtrl.dispose();
    _promoCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String get _maskedCard {
    final raw = _cardNumberCtrl.text.replaceAll(' ', '');
    if (raw.length >= 2) return '**** **** **** **${raw.substring(raw.length - 2)}';
    return '**** **** **** ****';
  }

  double get _finalTotal => widget.total - _discount;

  void _applyPromo() {
    final code = _promoCtrl.text.trim().toUpperCase();
    if (code == 'PROMO20' || code == 'PROMO20-08') {
      setState(() {
        _discount = widget.total * 0.20;
        _promoApplied = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Código aplicado — 20% de descuento'),
          backgroundColor: Color(0xFF4C6EF5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código inválido'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _goToConfirmation() {
    if (_cardNumberCtrl.text.isEmpty ||
        _expiryCtrl.text.isEmpty ||
        _cvvCtrl.text.isEmpty ||
        _holderCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _currentStep = 1);
    _slideCtrl.forward(from: 0);
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      final orderId = await DatabaseHelper.instance.saveOrder(
        List<Product>.from(widget.cartItems),
        _finalTotal,
        paymentMethod: _selectedMethod,
        cardHolder: _holderCtrl.text,
        cardLast4: _cardNumberCtrl.text.replaceAll(' ', '').length >= 4
            ? _cardNumberCtrl.text
                .replaceAll(' ', '')
                .substring(_cardNumberCtrl.text.replaceAll(' ', '').length - 4)
            : '****',
        promoCode: _promoApplied ? _promoCtrl.text.trim() : null,
        discount: _discount,
      );

      widget.onPaymentComplete();
      setState(() => _isProcessing = false);

      if (mounted) _showSuccessDialog(orderId);
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog(int orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFF4C6EF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const Text('¡Pago Exitoso!',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 8),
              Text('Orden #$orderId procesada',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 6),
              Text(
                '\$${_finalTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4C6EF5)),
              ),
              if (_promoApplied) ...[
                const SizedBox(height: 4),
                Text('Ahorraste \$${_discount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF4C6EF5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(c);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const OrderHistoryScreen()),
                      );
                    },
                    child: const Text('Ver órdenes',
                        style: TextStyle(color: Color(0xFF4C6EF5))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C6EF5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(c);
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('OK',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1A1A2E), size: 20),
          onPressed: () {
            if (_currentStep == 1) {
              setState(() => _currentStep = 0);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _currentStep == 0 ? 'Payment data' : 'Payment',
          style: const TextStyle(
              color: Color(0xFF1A1A2E),
              fontWeight: FontWeight.w600,
              fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _currentStep == 0 ? _buildStep1() : _buildStep2(),
    );
  }

  // ── PASO 1: Datos de tarjeta ──────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total
          const Text('Total price',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            '\$${widget.total.toStringAsFixed(2)}',
            style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4C6EF5)),
          ),
          const SizedBox(height: 28),

          // Método de pago
          const Text('Payment Method',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 14),
          Row(
            children: _methods.map((m) => _methodChip(m)).toList(),
          ),
          const SizedBox(height: 28),

          // Card number
          _buildLabel('Card number'),
          const SizedBox(height: 8),
          _buildCardField(
            controller: _cardNumberCtrl,
            hint: '**** **** **** ****',
            prefix: _cardIcon(),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CardNumberFormatter(),
            ],
            maxLength: 19,
          ),
          const SizedBox(height: 18),

          // Expiry + CVV
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Valid until'),
                    const SizedBox(height: 8),
                    _buildCardField(
                      controller: _expiryCtrl,
                      hint: 'Month / Year',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _ExpiryFormatter(),
                      ],
                      maxLength: 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('CVV'),
                    const SizedBox(height: 8),
                    _buildCardField(
                      controller: _cvvCtrl,
                      hint: '***',
                      obscure: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      maxLength: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Card holder
          _buildLabel('Card holder'),
          const SizedBox(height: 8),
          _buildCardField(
            controller: _holderCtrl,
            hint: 'Your name and surname',
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 24),

          // Save card toggle
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('Save card data for future payments',
                    style: TextStyle(
                        fontSize: 14, color: Color(0xFF1A1A2E))),
                const Spacer(),
                Switch(
                  value: _saveCard,
                  onChanged: (v) => setState(() => _saveCard = v),
                  activeColor: const Color(0xFF4C6EF5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Botón continuar
          _buildPrimaryButton(
            label: 'Proceed to confirm',
            onTap: _goToConfirmation,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── PASO 2: Confirmación ──────────────────────────────────────────────────
  Widget _buildStep2() {
    return SlideTransition(
      position: _slideAnim,
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner promo
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4C6EF5), Color(0xFF9B59B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Círculos decorativos
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 30,
                    bottom: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('\$50 off',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold)),
                        const Text('On your first order',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text(
                          '* Promo code valid for orders over \$150.',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Payment information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Payment information',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E))),
                GestureDetector(
                  onTap: () => setState(() => _currentStep = 0),
                  child: const Text('Edit',
                      style: TextStyle(
                          color: Color(0xFF4C6EF5),
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _cardIcon(),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _holderCtrl.text.isEmpty
                            ? 'Card holder'
                            : _holderCtrl.text,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1A1A2E)),
                      ),
                      Text(
                        '${_selectedMethod} Card ending $_maskedCard',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Promo code
            const Text('Use promo code',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _promoCtrl,
                      decoration: InputDecoration(
                        hintText: 'PROMO20-08',
                        hintStyle: TextStyle(
                            color: _promoApplied
                                ? Colors.green
                                : const Color(0xFF4C6EF5),
                            fontWeight: FontWeight.w500),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        suffixIcon: _promoApplied
                            ? const Icon(Icons.check_circle,
                                color: Colors.green)
                            : null,
                      ),
                      enabled: !_promoApplied,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _promoApplied ? null : _applyPromo,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: _promoApplied
                          ? Colors.green
                          : const Color(0xFF4C6EF5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _promoApplied ? '✓' : 'Apply',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Resumen de orden
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _summaryRow('Subtotal',
                      '\$${widget.total.toStringAsFixed(2)}'),
                  if (_promoApplied) ...[
                    const SizedBox(height: 8),
                    _summaryRow('Descuento',
                        '-\$${_discount.toStringAsFixed(2)}',
                        valueColor: Colors.green),
                  ],
                  const Divider(height: 20),
                  _summaryRow('Total',
                      '\$${_finalTotal.toStringAsFixed(2)}',
                      isBold: true,
                      valueColor: const Color(0xFF4C6EF5)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Botón pagar
            _isProcessing
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF4C6EF5)))
                : _buildPrimaryButton(
                    label: 'Pay',
                    onTap: _processPayment,
                  ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Widgets helpers ───────────────────────────────────────────────────────
  Widget _methodChip(String method) {
    final selected = _selectedMethod == method;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = method),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF4C6EF5) : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: selected
                    ? const Color(0xFF4C6EF5)
                    : Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Text(method,
                  style: TextStyle(
                      color: selected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              if (selected) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_circle,
                    color: Colors.white, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E)),
      );

  Widget _buildCardField({
    required TextEditingController controller,
    required String hint,
    Widget? prefix,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLength: maxLength,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: prefix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16),
          counterText: '',
        ),
      ),
    );
  }

  Widget _cardIcon() => Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEB001B),
                ),
              ),
            ),
            Positioned(
              right: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF79E1B).withOpacity(0.9),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildPrimaryButton(
      {required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4C6EF5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
          elevation: 4,
          shadowColor: const Color(0xFF4C6EF5).withOpacity(0.4),
        ),
        onPressed: onTap,
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight:
                    isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontWeight:
                    isBold ? FontWeight.bold : FontWeight.w600,
                fontSize: isBold ? 18 : 14,
                color: valueColor ?? const Color(0xFF1A1A2E))),
      ],
    );
  }
}

// ── Formatters ────────────────────────────────────────────────────────────────
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i % 4 == 0 && i != 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    return newValue.copyWith(
      text: buffer.toString(),
      selection:
          TextSelection.collapsed(offset: buffer.toString().length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('/', '');
    if (text.length >= 2) {
      final formatted = '${text.substring(0, 2)}/${text.substring(2)}';
      return newValue.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    return newValue;
  }
}