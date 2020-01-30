class ItemsController < ApplicationController
  before_action :move_to_login, only: [:new, :create]
  before_action :set_item, only: [:show, :edit, :destroy, :update]

  def index
    @parents = Category.where(ancestry: nil).page(params[:page]).per(4)
    @parents1 = Category.where(ancestry: nil, id: 1)
    @parents2 = Category.where(ancestry: nil, id: 200)
    @parents3 = Category.where(ancestry: nil, id: 346)
    @parents4 = Category.where(ancestry: nil, id: 481)
    @items1 = Item.joins(:item_images).select('items.id, items.buyer_id, items.name, items.price, item_images.image').where(category_id: 3).last(10).uniq
    @items2 = Item.joins(:item_images).select('items.id, items.buyer_id, items.name, items.price, item_images.image').where(category_id: 202).last(10).uniq
    @items3 = Item.joins(:item_images).select('items.id, items.buyer_id, items.name, items.price, item_images.image').where(category_id: 348).last(10).uniq
    @items4 = Item.joins(:item_images).select('items.id, items.buyer_id, items.name, items.price, item_images.image').where(category_id: 483).last(10).uniq
    @items = Item.joins(:item_images).select('items.id, items.buyer_id, items.name, items.price, item_images.image').last(10).uniq
  end

  def show
    @brand = Brand.find(@item.brand_id)
  end

  def buy_confirmation
    @card = Card.where(user_id: current_user.id).first 
    @item = Item.find(params[:item_id])
    @user = User.find(current_user.id)

    @image = ItemImage.find_by(item_id: params[:item_id])
    Payjp.api_key = Rails.application.credentials[:PAYJP_PRIVATE_KEY]
    customer = Payjp::Customer.retrieve(@card.customer_id)
    @default_card_information = customer.cards.retrieve(@card.card_id)
  end

  def new
    @item = Item.new
    @item.item_images.new
    #セレクトボックスの初期値設定
    @category_parent_array = ["---"]
    #データベースから、親カテゴリーのみ抽出し、配列化
    Category.where(ancestry: nil).each do |parent|
      @category_parent_array << parent.name
    end

  end

  def search
    @search_text = params[:keyword]
    redirect_to root_path if params[:keyword] == "" 
    split_keywords = params[:keyword].split(/[[:blank:]]+/)
    @items = Item.all

    split_keywords.each do |keyword|  # 分割したキーワードごとに検索
      next if keyword == "" 
      @items = @items.where( "name LIKE ? OR description LIKE ? ", "%#{keyword}%", "%#{keyword}%")
    end
  end

  def brand_search
    return nil if params[:keyword] == ""
    @brands = Brand.where(['name LIKE ?', "%#{params[:keyword]}%"] )
    respond_to do |format|
      format.html
      format.json
    end
  end
  # 以下全て、formatはjsonのみ
   # 親カテゴリーが選択された後に動くアクション
  def get_category_children
    #選択された親カテゴリーに紐付く子カテゴリーの配列を取得
    @category_children = Category.find_by(name: "#{params[:parent_name]}", ancestry: nil).children
  end

  # 子カテゴリーが選択された後に動くアクション
  def get_category_grandchildren
  #選択された子カテゴリーに紐付く孫カテゴリーの配列を取得
    @category_grandchildren = Category.find("#{params[:child_id]}").children
  end

  def create
    @item = Item.new(item_params)
    if @item.save
      redirect_to root_path
    else
      @category_parent_array = ["---"]
      Category.where(ancestry: nil).each do |parent|
        @category_parent_array << parent.name
      end
      @item.item_images.clear()
      @item.item_images.new
      render :new
    end
  end

  def edit
    @item = Item.find(params[:id])
    #セレクトボックスの初期値設定
    @category_parent_array = ["---"]
    #データベースから、親カテゴリーのみ抽出し、配列化
    Category.where(ancestry: nil).each do |parent|
      @category_parent_array << parent.name
    end
  end

  def update
    if @item.update(item_params)
      redirect_to item_path(@item.id)
    else
      render :edit
    end
  end

  def credit
  end

  def destroy
    if @item.destroy
      redirect_to root_path
    else
      render :show 
    end
  end

  
  private



  def item_params
    params.require(:item).permit(:name, :price, :description, :category_id, :condition, :shipping_charge, :shipping_method, :ship_form, :shipping_days, :brand_id, item_images_attributes: [:image, :_destroy, :id]).merge(user_id: current_user.id)
  end

  def set_item
    @item = Item.find(params[:id])
  end
end
