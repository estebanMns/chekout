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
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl     = TextEditingController();
  final _cvvCtrl        = TextEditingController();
  final _holderCtrl     = TextEditingController();
  final _promoCtrl      = TextEditingController();

  String _selectedMethod = 'Credit';
  bool   _saveCard       = false;
  bool   _promoApplied   = false;
  double _discount       = 0;
  bool   _isProcessing   = false;
  int    _currentStep    = 0;

  late AnimationController _slideCtrl;
  late Animation<Offset>   _slideAnim;

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

  String get _maskedCard {
    final raw = _cardNumberCtrl.text.replaceAll(' ', '');
    if (raw.length >= 4) return raw.substring(raw.length - 4);
    return '****';
  }

  double get _finalTotal => widget.total - _discount;

  void _applyPromo() {
    final code = _promoCtrl.text.trim().toUpperCase();
    if (code == 'PROMO20' || code == 'PROMO20-08') {
      setState(() {
        _discount     = widget.total * 0.20;
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
            backgroundColor: Colors.redAccent),
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
            backgroundColor: Colors.orange),
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
        widget.total,
        paymentMethod: _selectedMethod,
        cardHolder: _holderCtrl.text,
        cardLast4: _maskedCard,
        promoCode: _promoApplied ? _promoCtrl.text.trim() : null,
        discount: _discount,
      );

      // Limpiar carrito ANTES de navegar
      widget.onPaymentComplete();

      setState(() => _isProcessing = false);

      if (!mounted) return;

      // ── Navegar al historial reemplazando SOLO esta pantalla ─────────
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => _SuccessScreen(
            orderId: orderId,
            finalTotal: _finalTotal,
            discount: _discount,
            promoApplied: _promoApplied,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al procesar el pago: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

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

  // ── PASO 1 ────────────────────────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total price',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 6),
          Text('\$${widget.total.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4C6EF5))),
          const SizedBox(height: 28),

          const Text('Payment Method',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 14),
          Row(children: _methods.map(_methodChip).toList()),
          const SizedBox(height: 28),

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

          _buildLabel('Card holder'),
          const SizedBox(height: 8),
          _buildCardField(
            controller: _holderCtrl,
            hint: 'Your name and surname',
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Save card data for future payments',
                      style:
                          TextStyle(fontSize: 14, color: Color(0xFF1A1A2E))),
                ),
                Switch(
                  value: _saveCard,
                  onChanged: (v) => setState(() => _saveCard = v),
                  activeColor: const Color(0xFF4C6EF5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          _buildPrimaryButton(
              label: 'Proceed to confirm', onTap: _goToConfirmation),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── PASO 2 ────────────────────────────────────────────────────────────────
  Widget _buildStep2() {
    return SlideTransition(
      position: _slideAnim,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                  Positioned(
                    right: -20, top: -20,
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1)),
                    ),
                  ),
                  Positioned(
                    right: 30, bottom: -30,
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08)),
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

            // Payment info
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
                  borderRadius: BorderRadius.circular(16)),
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
                        '$_selectedMethod Card ending **$_maskedCard',
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
                        borderRadius: BorderRadius.circular(14)),
                    child: TextField(
                      controller: _promoCtrl,
                      enabled: !_promoApplied,
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
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Resumen
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
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

            _isProcessing
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF4C6EF5)))
                : _buildPrimaryButton(
                    label: 'Pay', onTap: _processPayment),
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

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A2E)));

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
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
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

  Widget _cardIcon() => SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 4,
              child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFEB001B))),
            ),
            Positioned(
              right: 4,
              child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          const Color(0xFFF79E1B).withOpacity(0.9))),
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

// ── Pantalla de éxito separada ────────────────────────────────────────────────
class _SuccessScreen extends StatelessWidget {
  final int orderId;
  final double finalTotal;
  final double discount;
  final bool promoApplied;

  const _SuccessScreen({
    required this.orderId,
    required this.finalTotal,
    required this.discount,
    required this.promoApplied,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                    color: Color(0xFF4C6EF5), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 50),
              ),
              const SizedBox(height: 28),
              const Text('¡Pago Exitoso!',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 10),
              Text('Orden #$orderId procesada correctamente',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 15)),
              const SizedBox(height: 12),
              Text('\$${finalTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4C6EF5))),
              if (promoApplied) ...[
                const SizedBox(height: 6),
                Text('Ahorraste \$${discount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C6EF5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    // Volver al home (quitar PaymentScreen y CartScreen)
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text('Volver al inicio',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF4C6EF5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const OrderHistoryScreen()),
                    );
                  },
                  child: const Text('Ver mis órdenes',
                      style: TextStyle(
                          color: Color(0xFF4C6EF5),
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
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
      final formatted =
          '${text.substring(0, 2)}/${text.substring(2)}';
      return newValue.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    return newValue;
  }
}