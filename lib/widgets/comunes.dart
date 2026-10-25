import 'package:flutter/material.dart';

import '../models.dart';

Color colorEstado(EstadoCupo e) => switch (e) {
      EstadoCupo.disponible => const Color(0xFF2E7D32),
      EstadoCupo.casiLleno => const Color(0xFF9A5B00),
      EstadoCupo.lleno => const Color(0xFFB3261E),
    };

String textoEstado(EstadoCupo e) => switch (e) {
      EstadoCupo.disponible => 'Disponible',
      EstadoCupo.casiLleno => 'Casi lleno',
      EstadoCupo.lleno => 'Lleno',
    };

IconData iconoEstado(EstadoCupo e) => switch (e) {
      EstadoCupo.disponible => Icons.check_circle_outline,
      EstadoCupo.casiLleno => Icons.warning_amber_rounded,
      EstadoCupo.lleno => Icons.block,
    };

/// Limita el ancho del contenido y lo centra (útil en tablets y escritorio).
class ContenidoCentrado extends StatelessWidget {
  const ContenidoCentrado({
    super.key,
    required this.child,
    this.anchoMaximo = 720,
  });

  final Widget child;
  final double anchoMaximo;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: anchoMaximo),
        child: child,
      ),
    );
  }
}

/// Etiqueta de estado: icono + texto + color (nunca solo color).
class EstadoChip extends StatelessWidget {
  const EstadoChip({super.key, required this.estado, this.etiqueta});

  final EstadoCupo estado;
  final String? etiqueta;

  @override
  Widget build(BuildContext context) {
    final color = colorEstado(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(110)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconoEstado(estado), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            etiqueta ?? textoEstado(estado),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra de ocupación de cupos de un grupo.
class CupoBar extends StatelessWidget {
  const CupoBar({super.key, required this.grupo, this.grande = false});

  final GrupoLab grupo;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final color = colorEstado(grupo.estado);
    final tema = Theme.of(context).textTheme;
    return Semantics(
      label:
          'Cupos ocupados ${grupo.cuposOcupados} de ${grupo.cuposTotales}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Cupos ocupados', style: tema.bodySmall),
              const Spacer(),
              Text(
                '${grupo.cuposOcupados}/${grupo.cuposTotales}',
                style: (grande ? tema.titleMedium : tema.bodyMedium)
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: grupo.ocupacion.clamp(0.0, 1.0).toDouble(),
              minHeight: grande ? 12 : 8,
              color: color,
              backgroundColor: color.withAlpha(40),
            ),
          ),
          if (grande) ...[
            const SizedBox(height: 6),
            Text(
              grupo.cuposLibres > 0
                  ? '${grupo.cuposLibres} cupos libres'
                  : 'Sin cupos libres',
              style: tema.bodySmall?.copyWith(color: color),
            ),
          ],
        ],
      ),
    );
  }
}

/// Cifra grande con su etiqueta (tarjetas de resumen).
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.valor, required this.etiqueta});

  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tema = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: tema.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onPrimaryContainer,
            ),
          ),
          Text(
            etiqueta,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tema.bodySmall?.copyWith(color: scheme.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

/// Mensaje con icono y fondo de color (avisos, advertencias).
class Aviso extends StatelessWidget {
  const Aviso({
    super.key,
    required this.icono,
    required this.texto,
    required this.color,
  });

  final IconData icono;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}

/// Estado vacío: icono grande, mensaje y (opcional) una acción.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.mensaje,
    this.etiquetaAccion,
    this.alAccionar,
  });

  final IconData icono;
  final String mensaje;
  final String? etiquetaAccion;
  final VoidCallback? alAccionar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 56, color: scheme.outline),
          const SizedBox(height: 12),
          Text(mensaje, textAlign: TextAlign.center),
          if (etiquetaAccion != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: alAccionar,
              child: Text(etiquetaAccion!),
            ),
          ],
        ],
      ),
    );
  }
}
