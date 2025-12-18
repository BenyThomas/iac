output "category_id" { value = try(vsphere_tag_category.cat[0].id, null) }
output "tag_ids" { value = { for k, v in vsphere_tag.tag : k => v.id } }
