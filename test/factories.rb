Factory.sequence :product_name do |n|
  "Product - " + [Time.now.tv_sec, Time.now.tv_usec, rand(9999)].join.split("").shuffle.join[0,9]
end

Factory.sequence :category_name do |n|
  "Category - " + [Time.now.tv_sec, Time.now.tv_usec, rand(9999)].join.split("").shuffle.join[0,9]
end

Factory.define :product, :class => Ansuz::NFine::Product do |p|
  p.name{ Factory.next(:product_name) }
  p.price 35.55
  p.description "Product Description"
end

Factory.define :category, :class => Ansuz::NFine::Category do |c|
  c.name{ Factory.next(:category_name) }
end

Factory.define :quantity_discount, :class => Ansuz::NFine::QuantityDiscount do |q|
  q.price '30.25'
  q.high_quantity '10'
  q.low_quantity '5'
end
