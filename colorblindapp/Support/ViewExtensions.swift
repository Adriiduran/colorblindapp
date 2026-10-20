//
//  ViewExtensions.swift
//  colorblindapp
//

import SwiftUI

extension View {
    /// Para textos de botón: evita que el contenido se corte o salte a dos
    /// líneas en pantallas estrechas — se mantiene en una línea y se escala
    /// hasta el 75% si hace falta. Con los tamaños de accesibilidad de
    /// Dynamic Type se permite saltar de línea: encoger el texto anularía
    /// justo el ajuste que el usuario ha pedido.
    func singleLineFitted() -> some View {
        modifier(SingleLineFitted())
    }
}

private struct SingleLineFitted: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            content
        } else {
            content
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }
}
