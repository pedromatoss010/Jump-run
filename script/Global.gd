extends Node

signal vida_alterada(nova_vida)
signal diamantes_alterados(total)

var proxima_fase: String = ""
var total_diamantes: int = 0
var max_vida: int = 5
var vida_atual: int = 5

var cena_origem: String = "res://scenes/mainMenu.tscn"

func resetar_status() -> void:
	vida_atual = max_vida

func alterar_vida(valor: int) -> void:
	vida_atual = clamp(valor, 0, max_vida)
	vida_alterada.emit(vida_atual)

func adicionar_diamante() -> void:
	total_diamantes += 1
	diamantes_alterados.emit(total_diamantes)
