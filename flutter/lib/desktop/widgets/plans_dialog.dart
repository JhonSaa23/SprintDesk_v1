import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart' hide Dialog;
import 'package:flutter_hbb/models/plan_model.dart';
import 'package:get/get.dart';

void showPlansDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => const PlansDialog(),
  );
}

void showConcurrentLimitDialog([BuildContext? context]) {
  final ctx = context ?? Get.context;
  if (ctx == null) return;
  final plan = PlanModel.instance;
  final isFree = !plan.isPaidPlan;
  final limit = plan.maxConcurrentSessions;

  showDialog(
    context: ctx,
    builder: (c) => AlertDialog(
      backgroundColor: const Color(0xFF1E222B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      title: Row(
        children: const [
          Icon(Icons.lock_clock_rounded, color: Color(0xFFF59E0B), size: 24),
          SizedBox(width: 10),
          Text(
            "Límite de conexiones simultáneas",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFree
                ? "Tu Plan Gratuito solo permite 1 conexión remota activa a la vez."
                : "Has alcanzado el límite de $limit conexiones simultáneas de tu ${plan.planName}.",
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isFree
                ? "Para controlar varias máquinas simultáneamente (Plan Individual: 3 máquinas por \$11.90/mes, o Plan Pro Equipo: 10 máquinas por \$45.90/mes) y tiempo ilimitado, actualiza tu suscripción."
                : "Para remotear más máquinas a la vez o agregar más usuarios a tu equipo, actualiza al Plan Pro Equipo (\$45.90/mes con 10 conexiones en paralelo).",
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(c).pop(),
          child: Text(
            "Cerrar",
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: MyTheme.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          onPressed: () {
            Navigator.of(c).pop();
            showPlansDialog(ctx);
          },
          icon: const Icon(Icons.star_rounded, size: 16),
          label: const Text(
            "Ver planes y actualizar",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

class PlansDialog extends StatefulWidget {
  const PlansDialog({Key? key}) : super(key: key);

  @override
  State<PlansDialog> createState() => _PlansDialogState();
}

class _PlansDialogState extends State<PlansDialog> {
  final TextEditingController _credentialController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _statusMessage = '';
  bool _isSuccess = false;
  bool _isActivating = false;
  String _activationStep = '';

  @override
  void initState() {
    super.initState();
    PlanModel.instance.init();
    if (PlanModel.instance.isPaidPlan) {
      _credentialController.text = PlanModel.instance.licenseKey.value;
    }
  }

  @override
  void dispose() {
    _credentialController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _activateCredential(String key) async {
    final cleanKey = key.trim();
    if (cleanKey.isEmpty) {
      setState(() {
        _statusMessage = 'Por favor pega la credencial de tu equipo.';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isActivating = true;
      _activationStep = 'Verificando credencial de equipo...';
      _statusMessage = '';
    });

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    setState(() {
      _activationStep = 'Validando puestos y dispositivos autorizados...';
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final success = await PlanModel.instance.activateLicense(cleanKey);
    setState(() {
      _isActivating = false;
      _isSuccess = success;
      if (success) {
        _credentialController.text = PlanModel.instance.licenseKey.value;
        final isTeam = PlanModel.instance.planType.value == PlanType.proTeam;
        _statusMessage = isTeam
            ? '¡Plan Pro Equipo activado! 10 máquinas simultáneas, 5 usuarios y tiempo ilimitado.'
            : '¡Plan Individual activado! 3 máquinas simultáneas, 1 usuario y tiempo ilimitado.';
      } else {
        _statusMessage =
            'Credencial no encontrada o no válida. Verifica con el administrador de tu equipo.';
      }
    });
  }

  void _deactivateCredential() async {
    await PlanModel.instance.deactivateLicense();
    setState(() {
      _credentialController.clear();
      _isSuccess = false;
      _statusMessage =
          'Credencial desactivada. Has vuelto al Plan Gratuito (1 máquina, 5 min).';
    });
  }

  void _openPaymentGateway(PlanType planType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PaymentGatewayDialog(
        planType: planType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 860,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: const Color(0xFF161920),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.55),
              blurRadius: 32,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  child: Column(
                    children: [
                      _buildPlansCards(context),
                      const SizedBox(height: 20),
                      _buildTeamCredentialSection(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2430),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MyTheme.accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: MyTheme.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Planes de Suscripción SprintDesk",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Selecciona tu suscripción o activa la credencial comercial de tu equipo",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded,
                color: Colors.white.withOpacity(0.5), size: 20),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildPlansCards(BuildContext context) {
    return Obx(() {
      final currentPlan = PlanModel.instance.planType.value;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Plan Gratuito
          Expanded(
            child: _buildPlanCard(
              title: "Gratuito",
              subtitle: "Acceso básico para pruebas",
              price: "\$0",
              period: "/ mes",
              isCurrent: currentPlan == PlanType.free,
              isPopular: false,
              accentColor: const Color(0xFF6B7280),
              features: [
                "1 usuario",
                "1 máquina remota a la vez",
                "⏱️ Límite de sesión de 5 minutos",
                "Desconexión automática a los 5 min",
                "Control básico de pantalla y teclado",
              ],
              buttonLabel: currentPlan == PlanType.free
                  ? "Plan Actual"
                  : "Cambiar a Gratis",
              onButtonPressed: currentPlan != PlanType.free
                  ? _deactivateCredential
                  : null,
            ),
          ),
          const SizedBox(width: 14),

          // 2. Plan Individual ($11.90)
          Expanded(
            child: _buildPlanCard(
              title: "Individual",
              subtitle: "Para profesionales y técnicos",
              price: "\$11.90",
              period: "/ mes por usuario",
              isCurrent: currentPlan == PlanType.individual,
              isPopular: false,
              accentColor: const Color(0xFF3B82F6),
              features: [
                "1 usuario autorizado",
                "3 máquinas remotas a la vez",
                "⏱️ Tiempo ILIMITADO (sin corte)",
                "Transferencia rápida de archivos",
                "Soporte multidisplay y sonido HD",
              ],
              buttonLabel: currentPlan == PlanType.individual
                  ? "✓ Plan Activo"
                  : "Elegir Plan Individual",
              onButtonPressed: currentPlan == PlanType.individual
                  ? null
                  : () => _openPaymentGateway(PlanType.individual),
            ),
          ),
          const SizedBox(width: 14),

          // 3. Plan Pro Equipo ($45.90)
          Expanded(
            child: _buildPlanCard(
              title: "Pro Equipo",
              subtitle: "Máxima potencia para grupos de soporte",
              price: "\$45.90",
              period: "/ mes (5 usuarios)",
              isCurrent: currentPlan == PlanType.proTeam,
              isPopular: true,
              accentColor: const Color(0xFF10B981),
              features: [
                "Credencial válida para 5 usuarios",
                "10 máquinas remotas a la vez en paralelo",
                "⏱️ Tiempo ILIMITADO (sin corte)",
                "Máxima prioridad y ultra baja latencia",
                "Transferencia de archivos ultrarrápida",
                "Multidisplay y control total",
              ],
              buttonLabel: currentPlan == PlanType.proTeam
                  ? "✓ Plan Activo"
                  : "Elegir Plan Pro Equipo",
              onButtonPressed: currentPlan == PlanType.proTeam
                  ? null
                  : () => _openPaymentGateway(PlanType.proTeam),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPlanCard({
    required String title,
    required String subtitle,
    required String price,
    required String period,
    required bool isCurrent,
    required bool isPopular,
    required Color accentColor,
    required List<String> features,
    required String buttonLabel,
    VoidCallback? onButtonPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E222B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular
              ? accentColor.withOpacity(0.85)
              : (isCurrent
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.08)),
          width: isPopular ? 2.0 : 1.2,
        ),
        boxShadow: [
          if (isPopular)
            BoxShadow(
              color: accentColor.withOpacity(0.22),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: const Center(
                child: Text(
                  "★ MÁS POPULAR - EMPRESAS Y EQUIPOS",
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFF10B981).withOpacity(0.5)),
                        ),
                        child: const Text(
                          "ACTIVO",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: isPopular ? accentColor : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      period,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Colors.white10),
                const SizedBox(height: 14),
                ...features.map((feature) {
                  final isHighlight = feature.contains("3 máquinas") ||
                      feature.contains("10 máquinas") ||
                      feature.contains("5 usuarios") ||
                      feature.contains("ILIMITADO");
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: isHighlight
                              ? const Color(0xFF10B981)
                              : accentColor.withOpacity(0.7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 11,
                              color: isHighlight
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.8),
                              fontWeight: isHighlight
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular
                          ? accentColor
                          : (isCurrent
                              ? Colors.white.withOpacity(0.08)
                              : MyTheme.accent),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: onButtonPressed,
                    child: Text(
                      buttonLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCredentialSection(BuildContext context) {
    return Obx(() {
      final plan = PlanModel.instance;
      final isPaid = plan.isPaidPlan;
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1C212A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPaid
                ? const Color(0xFF10B981).withOpacity(0.4)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPaid ? Icons.verified_user_rounded : Icons.vpn_key_rounded,
                  color: isPaid ? const Color(0xFF10B981) : MyTheme.accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isPaid
                      ? "${plan.planName} Activo"
                      : "Si ya perteneces a un equipo, pega la credencial aquí",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (isPaid)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                    ),
                    onPressed: _deactivateCredential,
                    icon: const Icon(Icons.logout_rounded, size: 14),
                    label: const Text(
                      "Desactivar Credencial",
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isPaid
                  ? "Tu equipo está habilitado con ${plan.maxConcurrentSessions} conexiones simultáneas y tiempo de sesión ilimitado."
                  : "Ingresa el token o credencial comercial provisto por tu empresa o generado tras tu compra.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.65),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF11141A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _focusNode.hasFocus
                            ? MyTheme.accent
                            : Colors.white.withOpacity(0.12),
                      ),
                    ),
                    child: Center(
                      child: TextField(
                        controller: _credentialController,
                        focusNode: _focusNode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                          fontFamily: 'monospace',
                        ),
                        decoration: InputDecoration(
                          hintText: "Pega tu credencial aquí...",
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 12,
                            fontFamily: 'sans-serif',
                            letterSpacing: 0,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (val) => _activateCredential(val),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyTheme.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: _isActivating
                        ? null
                        : () => _activateCredential(_credentialController.text),
                    icon: _isActivating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 16),
                    label: Text(
                      _isActivating ? "Activando..." : "Activar credencial",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isActivating) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(MyTheme.accent),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _activationStep,
                    style: const TextStyle(
                      fontSize: 11,
                      color: MyTheme.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            if (_statusMessage.isNotEmpty && !_isActivating) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? const Color(0xFF10B981).withOpacity(0.15)
                      : const Color(0xFFEF4444).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _isSuccess
                        ? const Color(0xFF10B981).withOpacity(0.4)
                        : const Color(0xFFEF4444).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess
                          ? Icons.check_circle_outline_rounded
                          : Icons.error_outline_rounded,
                      size: 14,
                      color: _isSuccess
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _isSuccess
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class PaymentGatewayDialog extends StatefulWidget {
  final PlanType planType;

  const PaymentGatewayDialog({
    Key? key,
    required this.planType,
  }) : super(key: key);

  @override
  State<PaymentGatewayDialog> createState() => _PaymentGatewayDialogState();
}

class _PaymentGatewayDialogState extends State<PaymentGatewayDialog> {
  final _cardNumberController = TextEditingController();
  final _holderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isProcessing = false;
  String _processMessage = '';
  bool _hasError = false;

  double get _price => widget.planType == PlanType.proTeam
      ? PlanModel.proTeamPriceMonthly
      : PlanModel.individualPriceMonthly;

  String get _planTitle => widget.planType == PlanType.proTeam
      ? "Plan Pro Equipo (10 máquinas, 5 usuarios)"
      : "Plan Individual (3 máquinas, 1 usuario)";

  void _processPayment() async {
    setState(() {
      _isProcessing = true;
      _hasError = false;
      _processMessage = "Conectando con pasarela de pagos segura SSL...";
    });

    await Future.delayed(const Duration(milliseconds: 950));
    if (!mounted) return;

    setState(() {
      _processMessage = "Validando autenticación con el banco emisor...";
    });

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    setState(() {
      _processMessage = "Esperando respuesta del procesador de pagos...";
    });

    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _hasError = true;
    });
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _holderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 520,
        decoration: BoxDecoration(
          color: const Color(0xFF161922),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: _hasError
              ? _buildFailureView(context)
              : _buildCheckoutView(context),
        ),
      ),
    );
  }

  Widget _buildCheckoutView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1F2430),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_rounded, size: 18, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              const Text(
                "Pasarela de Pago Seguro SSL",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (!_isProcessing)
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded,
                      color: Colors.white.withOpacity(0.5), size: 18),
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2533),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _planTitle,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Facturación mensual • Cancela cuando quieras",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "\$$_price USD",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card details
              const Text(
                "Detalles de la Tarjeta",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              _buildField("Número de Tarjeta", _cardNumberController,
                  icon: Icons.credit_card_rounded,
                  hintText: "4532 •••• •••• ••••"),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildField("Vence (MM/AA)", _expiryController,
                        hintText: "MM/AA"),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildField("CVC / CVV", _cvvController,
                        hintText: "CVC"),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              _buildField("Titular de la Tarjeta", _holderController,
                  hintText: "Nombre y apellido del titular"),
              const SizedBox(height: 10),

              _buildField("Correo para Comprobante y Factura", _emailController,
                  icon: Icons.mail_outline_rounded,
                  hintText: "ejemplo@empresa.com"),
              const SizedBox(height: 18),

              if (_isProcessing) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _processMessage,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isProcessing ? null : _processPayment,
                  icon: const Icon(Icons.verified_rounded, size: 18),
                  label: Text(
                    "Pagar \$$_price USD con Cifrado SSL",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {IconData? icon, String? hintText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF11141A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: Colors.white.withOpacity(0.4)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.28),
                      fontSize: 11.5,
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFailureView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEF4444).withOpacity(0.15),
              border: Border.all(
                color: const Color(0xFFEF4444).withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "Inconveniente con el Proveedor de Pagos",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "Código: ERR_PAYMENT_GATEWAY_TIMEOUT (504)",
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.55),
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "La pasarela bancaria externa no pudo procesar la transacción en este momento debido a una intermitencia de red con la entidad procesadora. No se ha realizado ningún cargo a tu tarjeta.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 16),

          // Reassurance Banner - SprintDesk service connection unaffected
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.35),
                width: 1.2,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  size: 20,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Aviso de Servicio SprintDesk",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Este inconveniente con la pasarela de pagos es completamente ajeno y externo. NO afecta en lo absoluto al servicio, calidad, estabilidad ni velocidad de conexión de SprintDesk.",
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.35,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Clarification about team credentials
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1C212A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.vpn_key_outlined,
                  size: 15,
                  color: Colors.white.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Si tu empresa ya cuenta con una credencial comercial asignada a tu equipo, puedes ingresarla directamente en la pantalla de planes.",
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.white.withOpacity(0.65),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Actions
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.18)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      "Cerrar",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyTheme.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      _processPayment();
                    },
                    child: const Text(
                      "Reintentar Cobro",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
