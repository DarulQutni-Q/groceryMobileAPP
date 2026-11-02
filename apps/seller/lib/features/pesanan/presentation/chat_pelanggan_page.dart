import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_shared/shared.dart';

import '../application/chat_provider.dart';

/// Chat toko dengan pelanggan tentang satu pesanan.
/// Sisi toko dari chat yang sama dengan yang dilihat pelanggan di
/// ChatDriverPage: pesan tersimpan di server per pesanan.
class ChatPelangganPage extends ConsumerStatefulWidget {
  const ChatPelangganPage({super.key, required this.order});
  final Pesanan order;

  @override
  ConsumerState<ChatPelangganPage> createState() => _ChatPelangganPageState();
}

class _ChatPelangganPageState extends ConsumerState<ChatPelangganPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  var _mengirim = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _sendText() async {
    final text = _input.text.trim();
    if (text.isEmpty || _mengirim) return;
    setState(() => _mengirim = true);
    try {
      await ref.read(chatApiTokoProvider).kirim(widget.order.id, text);
      _input.clear();
      ref.invalidate(chatTokoListProvider(widget.order.id));
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim pesan, coba lagi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _mengirim = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final messagesAsync = ref.watch(chatTokoListProvider(order.id));
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat • ${order.namaPembeli ?? order.kode}'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            color: Colors.grey.shade100,
            child: Text(
              'Pesanan #${order.kode} • ${order.status}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: TextButton(
                  key: const Key('chat-muat-ulang'),
                  onPressed: () =>
                      ref.invalidate(chatTokoListProvider(order.id)),
                  child: const Text('Gagal memuat. Coba lagi'),
                ),
              ),
              data: (messages) {
                _scrollToBottom();
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.refresh(chatTokoListProvider(order.id).future),
                  child: messages.isEmpty
                      ? ListView(
                          children: const [
                            Padding(
                              padding: EdgeInsets.only(top: 48),
                              child: Text(
                                'Belum ada pesan untuk pesanan ini.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (_, index) {
                            final pesan = messages[index];
                            final mine = pesan.dariToko;
                            final waktu = pesan.createdAt.toLocal();
                            return Align(
                              alignment: mine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 280,
                                ),
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                                decoration: BoxDecoration(
                                  color: mine
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      pesan.isi,
                                      style: TextStyle(
                                        color: mine
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${waktu.hour}:${waktu.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: mine
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('chat-input'),
                    controller: _input,
                    onSubmitted: (_) => _sendText(),
                    decoration: const InputDecoration(
                      hintText: 'Ketik pesan...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('chat-kirim'),
                  onPressed: _sendText,
                  icon: _mengirim
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
