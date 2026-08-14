import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../models/promotion.dart';
import '../models/promotion_store.dart';
import 'admin_promotion_edit_screen.dart';

class AdminPromotionsScreen extends StatefulWidget {
  const AdminPromotionsScreen({super.key});
  @override State<AdminPromotionsScreen> createState() => _AdminPromotionsScreenState();
}

class _AdminPromotionsScreenState extends State<AdminPromotionsScreen> {
  final store = PromotionStore.instance;
  String query = '';
  List<Promotion> get items {
    final q = query.trim().toLowerCase();
    return q.isEmpty ? store.items : store.items.where((p) => p.title.toLowerCase().contains(q)).toList();
  }
  Future<void> add() async { final p = await Navigator.push<Promotion>(context, MaterialPageRoute(builder: (_) => const AdminPromotionEditScreen())); if (p != null) setState(() => store.add(p)); }
  Future<void> edit(Promotion p) async { final r = await Navigator.push<Promotion>(context, MaterialPageRoute(builder: (_) => AdminPromotionEditScreen(promotion: p))); if (r != null) setState(() => store.update(r)); }
  void remove(Promotion p) => showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Удалить предложение?'), content: Text('«${p.title}» будет удалено.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')), FilledButton(onPressed: () { store.remove(p.id); Navigator.pop(context); setState(() {}); }, child: const Text('Удалить'))]));
  void duplicate(Promotion p) { store.add(Promotion(id: 'promo-${DateTime.now().microsecondsSinceEpoch}', title: '${p.title} — копия', description: p.description, bannerAsset: p.bannerAsset, bannerBytes: p.bannerBytes, pricingType: p.pricingType, discountPercent: p.discountPercent, products: p.products, isAvailable: false, createdAt: DateTime.now(), updatedAt: DateTime.now())); setState(() {}); }

  @override Widget build(BuildContext context) => Scaffold(backgroundColor: AppColors.background, body: SafeArea(child: CustomScrollView(slivers: [
    SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20,8,20,14), child: Row(children: [
      GestureDetector(onTap: () => Navigator.maybePop(context), child: Container(width:44,height:44,decoration: BoxDecoration(color:Colors.white,shape:BoxShape.circle,border:Border.all(color:AppColors.divider)),child:const Icon(Icons.chevron_left,color:AppColors.primaryBrown))),
      const SizedBox(width:14), Expanded(child:Text('Акции и спецпредложения',style:AppTextStyles.screenTitle)),
      GestureDetector(onTap:add,child:Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),decoration:BoxDecoration(color:AppColors.surfaceMuted,borderRadius:BorderRadius.circular(14)),child:const Row(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.add,size:17,color:AppColors.primaryBrown),SizedBox(width:5),Text('Добавить',style:TextStyle(fontWeight:FontWeight.w700,fontSize:13,color:AppColors.primaryBrown))])))
    ]))),
    SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.fromLTRB(20,0,20,12),child:TextField(onChanged:(v)=>setState(()=>query=v),decoration:InputDecoration(hintText:'Поиск акций и спецпредложений',prefixIcon:const Icon(Icons.search_rounded),filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.all(Radius.circular(18)),borderSide:BorderSide(color:AppColors.divider)),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.all(Radius.circular(18)),borderSide:BorderSide(color:AppColors.divider))))))),
    if(items.isEmpty) const SliverFillRemaining(hasScrollBody:false,child:Center(child:Text('Предложения не найдены'))) else SliverPadding(padding:const EdgeInsets.fromLTRB(20,4,20,28),sliver:SliverList.separated(itemCount:items.length,separatorBuilder:(_,__)=>const SizedBox(height:10),itemBuilder:(_,i)=>_Row(p:items[i],toggle:(v){store.setAvailability(items[i].id,v);setState((){});},tap:()=>edit(items[i]),more:()=>_more(items[i]))))
  ])));

  void _more(Promotion p) => showModalBottomSheet(context:context,backgroundColor:Colors.white,builder:(_)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
    ListTile(title:Text(p.title,style:const TextStyle(fontWeight:FontWeight.w700))),
    ListTile(leading:const Icon(Icons.edit_outlined),title:const Text('Редактировать'),onTap:(){Navigator.pop(context);edit(p);}),
    ListTile(leading:const Icon(Icons.copy_outlined),title:const Text('Дублировать'),onTap:(){Navigator.pop(context);duplicate(p);}),
    ListTile(leading:Icon(p.isAvailable?Icons.visibility_off_outlined:Icons.visibility_outlined),title:Text(p.isAvailable?'Сделать недоступным':'Сделать доступным'),onTap:(){store.setAvailability(p.id,!p.isAvailable);Navigator.pop(context);setState((){});}),
    ListTile(leading:const Icon(Icons.delete_outline,color:Colors.redAccent),title:const Text('Удалить'),onTap:(){Navigator.pop(context);remove(p);}),
  ]));
}

class _Row extends StatelessWidget {
  final Promotion p; final ValueChanged<bool> toggle; final VoidCallback tap,more;
  const _Row({required this.p,required this.toggle,required this.tap,required this.more});
  @override Widget build(BuildContext context){
    final image=p.bannerBytes!=null?Image.memory(Uint8List.fromList(p.bannerBytes!),width:94,height:70,fit:BoxFit.cover):p.bannerAsset!=null?Image.asset(p.bannerAsset!,width:94,height:70,fit:BoxFit.cover):Container(width:94,height:70,color:AppColors.surfaceMuted,child:const Icon(Icons.image_outlined,color:AppColors.primaryBrown));
    final n=p.products.length; final word=n%10==1&&n%100!=11?'товар':([2,3,4].contains(n%10)&&![12,13,14].contains(n%100)?'товара':'товаров');
    return GestureDetector(onTap:tap,child:Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(18),border:Border.all(color:AppColors.divider)),child:Row(children:[
      ClipRRect(borderRadius:BorderRadius.circular(12),child:image),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(p.title,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:15,fontWeight:FontWeight.w700,color:AppColors.textPrimary)),const SizedBox(height:4),Text('$n $word · ${p.pricingType==PromotionPricingType.discountPercent?'−${p.discountPercent??0}%':'спеццена'}',style:const TextStyle(fontSize:12,color:AppColors.textSecondary)),const SizedBox(height:5),Text(p.isAvailable?'Доступно клиентам':'Скрыто от клиентов',style:TextStyle(fontSize:11,fontWeight:FontWeight.w600,color:p.isAvailable?AppColors.primaryBrown:AppColors.textSecondary))])),Switch(value:p.isAvailable,onChanged:toggle,activeTrackColor:AppColors.primaryBrown),IconButton(onPressed:more,icon:const Icon(Icons.more_vert,color:AppColors.textSecondary),padding:EdgeInsets.zero,constraints:const BoxConstraints(minWidth:32,minHeight:32))
    ])));
  }
}
