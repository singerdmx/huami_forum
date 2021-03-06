module Admin
  class CategoriesController < BaseController
    include Connection

    def index
      @categories = attributes(Category.all)
    end

    def new
      @category = Category.new
    end

    def create
      category_name = params[:name]
      error_msg = nil
      if category_name.blank?
        error_msg = 'Category name can not be empty!'
        fail error_msg
      end

      unless params[:category_id].blank?
        update(Category, {id: params[:category_id]}, 'SET category_name = :val', {':val' => category_name})
        category_forums = Category.new_from_hash('id' => params[:category_id], 'category_name' => category_name).forums
        category_forums.each do |category_forum|
          update(Forum, {category: params[:category_id], id: category_forum['id']},
                 'SET category_name = :n', ':n' => category_name)
        end
        update_successful
      else
        if attributes(Category.all).find { |c| c['category_name'] == category_name }
          error_msg = "category '#{category_name}' already exists"
          fail error_msg
        end
        Category.create(category_name: category_name)
        create_successful
      end
    rescue Exception => e
      Rails.logger.error "Encountered an error: #{e.inspect}\nbacktrace: #{e.backtrace}"
      if params[:category_id].blank?
        create_failed error_msg || t("forem.admin.category.not_created")
      else
        update_failed error_msg || t("forem.admin.category.not_updated")
      end
    end

    def edit
      get_category_from_params :id
    end

    def destroy
      category_name = params[:category_name]
      category_forums = Category.new_from_hash('id' => params[:id], 'category_name' => category_name).forums
      if category_forums.empty?
        delete(Category, {id: params[:id]})
        destroy_successful
      else
        destroy_failed "Category #{category_name} can not be deleted having forum(s): #{category_forums.map { |f| f['forum_name'] }.join(', ')}"
      end
    end

    private

    def create_successful
      flash[:notice] = t("forem.admin.category.created")
      redirect_to admin_categories_path
    end

    def create_failed(alert_msg)
      flash[:error] = alert_msg
      @category = Category.new
      render action: 'new'
    end

    def destroy_successful
      flash[:notice] = t("forem.admin.category.deleted")
      redirect_to admin_categories_path
    end

    def destroy_failed(alert_msg)
      flash[:notice] = alert_msg
      redirect_to admin_categories_path
    end

    def update_successful
      flash[:notice] = t("forem.admin.category.updated")
      redirect_to admin_categories_path
    end

    def update_failed(alert_msg)
      flash[:notice] = alert_msg
      get_category_from_params :category_id
      render action: 'edit'
    end

    def get_category_from_params(id_key)
      category = get(Category, {id: params[id_key]})
      @category = Category.new_from_hash(category)
    end

  end
end
