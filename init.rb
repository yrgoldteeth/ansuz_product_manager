#Register the admin menu instances for managing products and creating a new product.
Ansuz::PluginManagerInstance.register_admin_menu_entry('Manage', 'Products', '/admin/products')
Ansuz::PluginManagerInstance.register_admin_menu_entry('Manage', 'Product Categories', '/admin/categories')
